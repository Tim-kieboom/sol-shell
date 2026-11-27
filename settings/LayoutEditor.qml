import QtQuick
import QtQuick.Layouts
import "../singletons"
import "../utils/layoutMove.js" as Move

// The layout editor: where the items of the bar sit, written to bar-layout.json (see
// BarLayoutService). Without that file the bar is laid out by its style; "Customize" makes the file
// from the style's layout, and "Reset" deletes it again.
Item {
    id: root

    implicitHeight: column.implicitHeight

    // the saved layouts are looked up when the editor opens
    Component.onCompleted: BarLayoutService.refreshSaved()

    // ---- dragging ----
    //
    // A chip that is pressed becomes `dragging`; a copy of it (the proxy at the end of this file) follows
    // the pointer and is what the drop areas see. On release the drop area under the proxy says where the
    // item goes (`dropOn`). The chips stay where they are meanwhile, so the layout does not jump about.

    // the name of the item being dragged, or ""
    property string dragging: ""
    // whether the dragged item has a line in the dropdown (only some items do); true while nothing is dragged
    readonly property bool draggingFitsMenu: dragging === "" || Move.MENU_ATOMS.includes(dragging)
    // whether the layout has its dropdown already (there is at most one)
    readonly property bool hasMenu: BarLayoutService.layout ? Move.hasMenu(BarLayoutService.layout) : false
    // goes up with every drop: a place for a new pill that was not used closes
    property int dropCount: 0

    function beginDrag(atom: string): void {
        dragging = atom;
    }

    // `point` is where the pointer is, in this item's coordinates
    function dragTo(point: point): void {
        proxy.x = point.x - proxy.width / 2;
        proxy.y = point.y - proxy.height / 2;
    }

    // let go: the drop area under the proxy gets its drop (and calls dropOn), then the drag is over
    function endDrag(): void {
        if (dragging === "")
            return;
        proxy.Drag.drop();
        dragging = "";
    }

    function cancelDrag(): void {
        dragging = "";
    }

    // where the dragged item goes: a target as in utils/layoutMove.js, or { unplace: true }
    function dropOn(target: var): void {
        const name = dragging;
        dropCount += 1;
        if (target.unplace === true)
            BarLayoutService.unplace(name);
        else
            BarLayoutService.move(name, target);
    }

    Column {
        id: column
        width: root.width
        spacing: 10

        // the names the layout puts somewhere
        readonly property var placed: {
            const names = [];
            const layout = BarLayoutService.layout;
            if (!layout)
                return names;
            for (const side of ["left", "center", "right"]) {
                for (const entry of layout[side]) {
                    for (const name of Move.members(entry) ?? [entry])
                        names.push(name);
                }
            }
            return names;
        }

        // the items the layout does not list are hidden; the dropdown itself is not an item to place
        readonly property var unplaced: BarStyle.atomNames.filter(name => !placed.includes(name) && name !== BarStyle.compactMenuAtom)

        // the look of the bar: its style, and the edge of the screen it sits on
        Text {
            text: "Style"
            color: Theme.secondaryText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.labelMedium
        }

        Flow {
            width: root.width
            spacing: 8

            Repeater {
                model: BarStyle.styleList

                StyleChip {
                    required property var modelData
                    entry: modelData
                }
            }
        }

        RowLayout {
            width: root.width
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: "Position"
                color: Theme.secondaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelMedium
            }

            LayoutButton {
                text: "Top"
                primary: BarStyle.position === "top"
                onClicked: Settings.barPosition = "top"
            }

            LayoutButton {
                text: "Bottom"
                primary: BarStyle.position === "bottom"
                onClicked: Settings.barPosition = "bottom"
            }
        }

        Text {
            width: root.width
            wrapMode: Text.WordWrap
            text: BarLayoutService.active
                ? "Your own layout is in use (bar-layout.json). A box with a border is a pill, and a dashed one is the dropdown."
                : "The bar is laid out by its style. Customize makes your own layout from it: you can then move the items between the sides and group them into pills."
            color: Theme.mutedText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.labelSmall
        }

        // the file exists but cannot be used
        Text {
            visible: BarLayoutService.problem !== ""
            width: root.width
            wrapMode: Text.WordWrap
            text: "bar-layout.json cannot be used: " + BarLayoutService.problem + ". Reset deletes it."
            color: Theme.danger
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.labelSmall
        }

        Row {
            spacing: 8

            // Customize: only while the style's own layout is in use
            Rectangle {
                visible: !BarLayoutService.active && BarLayoutService.problem === ""
                width: customizeLabel.implicitWidth + 28
                height: 30
                radius: 15
                color: customizeMouse.containsMouse ? Theme.surface : "transparent"
                border.width: 2
                border.color: Theme.accent

                Text {
                    id: customizeLabel
                    anchors.centerIn: parent
                    text: "Customize"
                    color: Theme.primaryText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.labelMedium
                }

                MouseArea {
                    id: customizeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: BarLayoutService.customize()
                }
            }

            // Reset: while a file exists, usable or not
            Rectangle {
                visible: BarLayoutService.active || BarLayoutService.problem !== ""
                width: resetLabel.implicitWidth + 28
                height: 30
                radius: 15
                color: resetMouse.containsMouse ? Theme.surface : "transparent"
                border.width: 1
                border.color: Theme.surfaceBorder

                Text {
                    id: resetLabel
                    anchors.centerIn: parent
                    text: "Reset"
                    color: Theme.primaryText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.labelMedium
                }

                MouseArea {
                    id: resetMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: BarLayoutService.reset()
                }
            }
        }

        // presets: ready-made arrangements; one makes it your layout (and replaces the one you have)
        Column {
            width: root.width
            spacing: 4

            Text {
                text: "Presets"
                color: Theme.secondaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelMedium
            }

            Flow {
                width: root.width
                spacing: 6

                Repeater {
                    // only the id and the name: the layout itself stays in the service
                    model: BarLayoutService.presets.map(preset => ({ id: preset.id, label: preset.label }))

                    LayoutButton {
                        required property var modelData
                        text: modelData.label
                        onClicked: BarLayoutService.applyPreset(modelData.id)
                    }
                }
            }
        }

        // layouts you saved: one makes it the layout in use, the cross deletes it; a name and "Save" keep
        // the layout in use under that name
        Column {
            width: root.width
            spacing: 4

            Text {
                text: "Your layouts"
                color: Theme.secondaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelMedium
            }

            Flow {
                width: root.width
                spacing: 6

                Repeater {
                    model: BarLayoutService.saved

                    Row {
                        required property string modelData
                        spacing: 2

                        LayoutButton {
                            text: parent.modelData
                            onClicked: BarLayoutService.applySaved(parent.modelData)
                        }

                        LayoutButton {
                            text: "\u00d7"
                            onClicked: BarLayoutService.deleteSaved(parent.modelData)
                        }
                    }
                }

                Text {
                    visible: BarLayoutService.saved.length === 0
                    text: "none yet"
                    color: Theme.mutedText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.labelSmall
                }
            }

            Row {
                spacing: 8

                Rectangle {
                    width: 200
                    height: 30
                    radius: 8
                    color: Theme.shellBackground
                    border.width: 1
                    border.color: nameInput.activeFocus ? Theme.accent : (nameInput.text !== "" && !BarLayoutService.validName(nameInput.text) ? Theme.danger : Theme.surfaceBorder)

                    TextInput {
                        id: nameInput
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.primaryText
                        font.family: Fonts.bodyFontFamily
                        font.pixelSize: Fonts.labelMedium
                        clip: true
                        maximumLength: 40
                        onAccepted: saveButton.clicked()

                        Text {
                            visible: nameInput.text === "" && !nameInput.activeFocus
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Name for this layout"
                            color: Theme.mutedText
                            font: nameInput.font
                        }
                    }
                }

                LayoutButton {
                    id: saveButton
                    text: "Save"
                    enabled: BarLayoutService.active && BarLayoutService.validName(nameInput.text)
                    onClicked: {
                        if (BarLayoutService.saveAs(nameInput.text))
                            nameInput.text = "";
                    }
                }
            }

            Text {
                width: root.width
                wrapMode: Text.WordWrap
                text: BarLayoutService.active
                    ? "Saved in ~/.config/quickshell/bar-layouts/. Letters, digits, spaces, - and _."
                    : "Customize or pick a preset first: Save keeps the layout that is in use."
                color: Theme.mutedText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelSmall
            }
        }

        // the three sides, while your layout is in use
        LayoutZone {
            visible: BarLayoutService.active
            width: root.width
            title: "Left"
            side: "left"
            editor: root
            entries: BarLayoutService.layout?.left ?? []
        }

        LayoutZone {
            visible: BarLayoutService.active
            width: root.width
            title: "Center"
            side: "center"
            editor: root
            entries: BarLayoutService.layout?.center ?? []
        }

        LayoutZone {
            visible: BarLayoutService.active
            width: root.width
            title: "Right"
            side: "right"
            editor: root
            entries: BarLayoutService.layout?.right ?? []
        }

        // the items the layout does not list are not in the bar: dropping an item here hides it
        Column {
            visible: BarLayoutService.active
            width: root.width
            spacing: 4

            Text {
                text: "Hidden"
                color: Theme.secondaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelMedium
            }

            Rectangle {
                width: root.width
                implicitHeight: unplacedFlow.implicitHeight + 16
                radius: 8
                color: "transparent"
                border.width: 1
                border.color: unplacedDrop.containsDrag ? Theme.accent : Theme.surfaceBorder

                DropArea {
                    id: unplacedDrop
                    anchors.fill: parent
                    onDropped: root.dropOn({ unplace: true })
                }

                Flow {
                    id: unplacedFlow
                    x: 8
                    y: 8
                    width: parent.width - 16
                    spacing: 6

                    Repeater {
                        model: column.unplaced

                        LayoutChip {
                            required property string modelData
                            atom: modelData
                            dim: true
                            editor: root
                        }
                    }

                    Text {
                        visible: column.unplaced.length === 0
                        text: "nothing is hidden: drag an item here to hide it"
                        color: Theme.mutedText
                        font.family: Fonts.bodyFontFamily
                        font.pixelSize: Fonts.labelSmall
                    }
                }
            }

            Text {
                width: root.width
                wrapMode: Text.WordWrap
                text: "These are not in the bar. Drag one into a side to show it. The settings item cannot be hidden: it is the way back here."
                color: Theme.mutedText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelSmall
            }
        }
    }

    // the copy of the dragged chip that follows the pointer; it is what the drop areas react to
    LayoutChip {
        id: proxy
        atom: root.dragging !== "" ? root.dragging : "settings"
        visible: root.dragging !== ""
        z: 100
        Drag.active: visible
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2
    }
}
