import QtQuick
import "../singletons"

// The dropdown in the layout editor: a dashed box with a grip, its name and the items in it. It sits on a side
// or inside a pill. Drop an item on the empty part to put it at its end; it turns red while you drag an item
// that has no line in the menu.
Rectangle {
    id: root

    // the names of the items in the dropdown
    required property var atoms
    required property var editor

    implicitHeight: row.implicitHeight + 12
    radius: 14
    color: "transparent"
    border.width: drop.containsDrag ? 2 : 1
    border.color: root.editor.draggingFitsMenu ? Theme.secondaryText : Theme.danger

    DropArea {
        id: drop
        anchors.fill: parent
        onDropped: {
            if (root.atoms.length > 0)
                root.editor.dropOn({ endOfPillWith: root.atoms[0] });
        }
    }

    Flow {
        id: row
        x: 6
        y: 6
        width: parent.width - 12
        spacing: 6

        LayoutGrip {
            kind: "menu"
            editor: root.editor
        }

        Text {
            height: 26
            verticalAlignment: Text.AlignVCenter
            text: root.editor.draggingFitsMenu ? "dropdown:" : "dropdown: only volume, Wi-Fi, Bluetooth, color picker, night light and keep awake fit here"
            color: root.editor.draggingFitsMenu ? Theme.secondaryText : Theme.danger
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.labelSmall
        }

        Repeater {
            model: root.atoms

            LayoutChip {
                required property string modelData
                atom: modelData
                editor: root.editor
            }
        }
    }
}
