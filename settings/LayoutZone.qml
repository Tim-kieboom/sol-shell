import QtQuick
import "../singletons"

// One side of the bar in the layout editor (left, center or right): its title and the entries in it.
// An entry is a chip, or a pill: a box with chips in it. Dropping on the empty part of the side puts
// the item at its end; "Pill" opens a place to drop an item that becomes a new pill.
Column {
    id: root

    property string title
    // "left", "center" or "right"
    property string side
    // names, and lists of names (pills): what the layout file holds for this side
    property var entries: []
    // the editor this side belongs to (LayoutEditor.qml)
    property var editor: null

    // an entry of this side made into the plain object the delegates read: { kind: "chip" | "pill" | "menu", atom,
    // items, atoms, anchor }. `items` are the things in a pill (items and maybe the dropdown); `anchor` is one item
    // directly in the pill, which is how a pill is found ("" when it holds only the dropdown).
    function describe(entry: var): var {
        if (Array.isArray(entry)) {
            return {
                kind: "pill",
                atom: "",
                items: entry.map(inner => typeof inner === "object" ? { menu: true, atom: "", atoms: inner.menu } : { menu: false, atom: inner, atoms: [] }),
                atoms: [],
                anchor: entry.find(inner => typeof inner === "string") ?? ""
            };
        }
        if (typeof entry === "object")
            return { kind: "menu", atom: "", items: [], atoms: entry.menu, anchor: "" };
        return { kind: "chip", atom: entry, items: [], atoms: [], anchor: "" };
    }

    // whether the place for a new pill is open
    property bool pillOpen: false
    // whether the place for the dropdown is open
    property bool menuOpen: false

    spacing: 4

    // an empty pill that is not used is closed again after any drop
    Connections {
        target: root.editor
        function onDropCountChanged(): void {
            root.pillOpen = false;
            root.menuOpen = false;
        }
    }

    Item {
        width: root.width
        height: 20

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.title
            color: Theme.secondaryText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.labelMedium
        }

        // the buttons that open a place for a new pill, or for the dropdown (there is at most one)
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Rectangle {
                visible: root.editor !== null && !root.editor.hasMenu && !root.menuOpen
                width: menuButtonLabel.implicitWidth + 16
                height: 20
                radius: 10
                color: menuButtonMouse.containsMouse ? Theme.surface : "transparent"
                border.width: 1
                border.color: Theme.surfaceBorder

                Text {
                    id: menuButtonLabel
                    anchors.centerIn: parent
                    text: "+ Dropdown"
                    color: Theme.secondaryText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.labelSmall
                }

                MouseArea {
                    id: menuButtonMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.menuOpen = true
                }
            }

            Rectangle {
                visible: !root.pillOpen
                width: pillLabel.implicitWidth + 16
                height: 20
                radius: 10
                color: pillMouse.containsMouse ? Theme.surface : "transparent"
                border.width: 1
                border.color: Theme.surfaceBorder

                Text {
                    id: pillLabel
                    anchors.centerIn: parent
                    text: "+ Pill"
                    color: Theme.secondaryText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.labelSmall
                }

                MouseArea {
                    id: pillMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.pillOpen = true
                }
            }
        }
    }

    Rectangle {
        width: root.width
        implicitHeight: flow.implicitHeight + 16
        radius: 8
        color: Theme.shellBackground
        border.width: 1
        border.color: zoneDrop.containsDrag ? Theme.accent : Theme.surfaceBorder

        // the whole side: a drop that lands on nothing else goes to its end
        DropArea {
            id: zoneDrop
            anchors.fill: parent
            onDropped: root.editor.dropOn({ end: root.side })
        }

        Flow {
            id: flow
            x: 8
            y: 8
            width: parent.width - 16
            spacing: 6

            Repeater {
                // A nested list does not stay a list when a Repeater hands it to its delegate, so each entry is
                // made into an object first (see `describe`).
                model: root.entries.map(root.describe)

                Loader {
                    required property var modelData

                    sourceComponent: modelData.kind === "pill" ? pill : (modelData.kind === "menu" ? menuBox : chip)

                    Component {
                        id: chip
                        LayoutChip {
                            atom: modelData.atom
                            editor: root.editor
                        }
                    }

                    // the dropdown on this side, on a line of its own
                    Component {
                        id: menuBox
                        LayoutMenuBox {
                            width: flow.width
                            atoms: modelData.atoms
                            editor: root.editor
                        }
                    }

                    // a pill: its own box on a line of its own, with a grip and the items inside (the dropdown too,
                    // if it is in this pill); dropping on the empty part of it puts the item at its end
                    Component {
                        id: pill
                        Rectangle {
                            width: flow.width
                            implicitHeight: inner.implicitHeight + 12
                            radius: 14
                            color: "transparent"
                            border.width: pillDrop.containsDrag ? 2 : 1
                            border.color: Theme.accent

                            DropArea {
                                id: pillDrop
                                anchors.fill: parent
                                // a pill that holds only the dropdown has nothing to drop "at the end of the pill" on
                                enabled: modelData.anchor !== ""
                                onDropped: root.editor.dropOn({ endOfPillWith: modelData.anchor })
                            }

                            Column {
                                id: inner
                                x: 6
                                y: 6
                                width: parent.width - 12
                                spacing: 6

                                // the items directly in the pill, with the grip first
                                Flow {
                                    width: parent.width
                                    spacing: 6
                                    visible: modelData.anchor !== ""

                                    LayoutGrip {
                                        kind: "pill"
                                        ref: modelData.anchor
                                        editor: root.editor
                                    }

                                    Repeater {
                                        model: modelData.items.filter(item => !item.menu)

                                        LayoutChip {
                                            required property var modelData
                                            atom: modelData.atom
                                            editor: root.editor
                                        }
                                    }
                                }

                                // the dropdown, when it is in this pill
                                Repeater {
                                    model: modelData.items.filter(item => item.menu)

                                    LayoutMenuBox {
                                        required property var modelData
                                        width: inner.width
                                        atoms: modelData.atoms
                                        editor: root.editor
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // the open place for the dropdown: red while you drag an item that has no menu line
            Rectangle {
                visible: root.menuOpen
                width: flow.width
                height: 38
                radius: 14
                color: "transparent"
                border.width: newMenuDrop.containsDrag ? 2 : 1
                border.color: root.editor.draggingFitsMenu ? Theme.secondaryText : Theme.danger

                DropArea {
                    id: newMenuDrop
                    anchors.fill: parent
                    onDropped: root.editor.dropOn({ newMenu: root.side })
                }

                Text {
                    anchors.centerIn: parent
                    text: root.editor.draggingFitsMenu ? "Drop an item here for the dropdown" : "This item has no line in the dropdown yet"
                    color: root.editor.draggingFitsMenu ? Theme.mutedText : Theme.danger
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.labelSmall
                }
            }

            // the open place for a new pill
            Rectangle {
                visible: root.pillOpen
                width: flow.width
                height: 38
                radius: 14
                color: "transparent"
                border.width: newPillDrop.containsDrag ? 2 : 1
                border.color: Theme.accent

                DropArea {
                    id: newPillDrop
                    anchors.fill: parent
                    onDropped: root.editor.dropOn({ newPill: root.side })
                }

                Text {
                    anchors.centerIn: parent
                    text: "Drop an item here for a new pill"
                    color: Theme.mutedText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.labelSmall
                }
            }

            Text {
                visible: root.entries.length === 0 && !root.pillOpen && !root.menuOpen
                text: "empty"
                color: Theme.mutedText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelSmall
            }
        }
    }
}
