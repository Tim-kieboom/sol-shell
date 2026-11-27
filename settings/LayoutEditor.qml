import QtQuick
import QtQuick.Layouts
import "../singletons"

// The layout editor: where the items of the bar sit, written to bar-layout.json (see
// BarLayoutService). Without that file the bar is laid out by its style; "Customize" makes the file
// from the style's layout, and "Reset" deletes it again.
Item {
    id: root

    implicitHeight: column.implicitHeight

    // ---- dragging ----
    //
    // A chip that is pressed becomes `dragging`; a copy of it (the proxy at the end of this file) follows
    // the pointer and is what the drop areas see. On release the drop area under the proxy says where the
    // item goes (`dropOn`). The chips stay where they are meanwhile, so the layout does not jump about.

    // the name of the item being dragged, or ""
    property string dragging: ""
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
                    for (const name of Array.isArray(entry) ? entry : [entry])
                        names.push(name);
                }
            }
            return names;
        }

        // items that are not placed sit at the end of the side where the style has them; the compact
        // menu is the compact bar's own
        readonly property var unplaced: BarStyle.atomNames.filter(name => !placed.includes(name) && name !== BarStyle.compactMenuAtom)

        Text {
            width: root.width
            wrapMode: Text.WordWrap
            text: BarLayoutService.active
                ? "Your own layout is in use (bar-layout.json). A box with a border is a pill."
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

        // items the layout does not place; dropping an item here takes it out of your layout
        Column {
            visible: BarLayoutService.active
            width: root.width
            spacing: 4

            Text {
                text: "Not placed"
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
                        text: "nothing: drag an item here to take it out of your layout"
                        color: Theme.mutedText
                        font.family: Fonts.bodyFontFamily
                        font.pixelSize: Fonts.labelSmall
                    }
                }
            }

            Text {
                width: root.width
                wrapMode: Text.WordWrap
                text: "These are added at the end of the side where the style has them (the ones that start hidden stay hidden until switched on under Bar items)."
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
