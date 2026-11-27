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
                // A nested list does not stay a list when a Repeater hands it to its delegate, so each
                // entry is made into an object first: { pill, atom } for a chip, { pill, atoms } for a pill.
                // The dropdown ({ menu: [names] }) is drawn like a pill, with a dashed look and its name.
                model: root.entries.map(entry => Array.isArray(entry) ? { pill: true, menu: false, atom: "", atoms: entry } : (typeof entry === "object" ? { pill: true, menu: true, atom: "", atoms: entry.menu } : { pill: false, menu: false, atom: entry, atoms: [] }))

                Loader {
                    required property var modelData

                    sourceComponent: modelData.pill ? pill : chip

                    Component {
                        id: chip
                        LayoutChip {
                            atom: modelData.atom
                            editor: root.editor
                        }
                    }

                    // a pill: its own box on a line of its own, with the chips inside; dropping on the
                    // empty part of it puts the item at its end
                    Component {
                        id: pill
                        Rectangle {
                            width: flow.width
                            implicitHeight: inner.implicitHeight + 12
                            radius: 14
                            color: "transparent"
                            border.width: pillDrop.containsDrag ? 2 : 1
                            // the dropdown takes only the items that have a menu line: red while you drag another
                            border.color: modelData.menu ? (root.editor.draggingFitsMenu ? Theme.secondaryText : Theme.danger) : Theme.accent

                            DropArea {
                                id: pillDrop
                                anchors.fill: parent
                                onDropped: root.editor.dropOn({ endOfPillWith: modelData.atoms[0] })
                            }

                            Flow {
                                id: inner
                                x: 6
                                y: 6
                                width: parent.width - 12
                                spacing: 6

                                Text {
                                    visible: modelData.menu
                                    height: 26
                                    verticalAlignment: Text.AlignVCenter
                                    text: root.editor.draggingFitsMenu ? "dropdown:" : "dropdown: only volume, Wi-Fi, Bluetooth, color picker, night light and keep awake fit here"
                                    color: root.editor.draggingFitsMenu ? Theme.secondaryText : Theme.danger
                                    font.family: Fonts.bodyFontFamily
                                    font.pixelSize: Fonts.labelSmall
                                }

                                Repeater {
                                    model: modelData.atoms

                                    LayoutChip {
                                        required property string modelData
                                        atom: modelData
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
