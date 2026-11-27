import QtQuick
import "../singletons"

// One item of the bar, drawn as a small chip in the layout editor: the item's name for people
// ("Wi-Fi"). Dimmed when the item is not placed by your layout.
//
// With an `editor` (LayoutEditor.qml) the chip can be dragged, and a placed chip is a place to drop
// another one: on its left half the dragged item goes before it, on its right half after it.
Rectangle {
    id: root

    required property string atom
    property bool dim: false
    // the editor this chip belongs to, or null for a chip that only shows
    property var editor: null
    // a chip that can be dropped on (placed chips; the "not placed" ones can only be dragged)
    property bool target: !dim

    readonly property bool beingDragged: editor !== null && editor.dragging === atom

    implicitWidth: label.implicitWidth + 20
    implicitHeight: 26
    radius: height / 2
    color: dim ? "transparent" : Theme.surface
    border.width: 1
    border.color: dim ? Theme.surfaceBorder : Theme.accent
    opacity: beingDragged ? 0.3 : (dim ? 0.7 : 1.0)

    Text {
        id: label
        anchors.centerIn: parent
        text: BarStyle.atomLabels[root.atom] ?? root.atom
        color: root.dim ? Theme.mutedText : Theme.primaryText
        font.family: Fonts.bodyFontFamily
        font.pixelSize: Fonts.labelMedium
    }

    // the two halves a dragged item can be dropped on, with a bar on the edge it would go to
    DropArea {
        visible: root.editor !== null && root.target
        enabled: visible
        x: 0
        width: root.width / 2
        height: root.height
        onDropped: root.editor.dropOn({ before: root.atom })

        Rectangle {
            visible: parent.containsDrag
            x: -4
            width: 3
            height: root.height
            radius: 1.5
            color: Theme.accent
        }
    }

    DropArea {
        visible: root.editor !== null && root.target
        enabled: visible
        x: root.width / 2
        width: root.width / 2
        height: root.height
        onDropped: root.editor.dropOn({ after: root.atom })

        Rectangle {
            visible: parent.containsDrag
            x: parent.width + 1
            width: 3
            height: root.height
            radius: 1.5
            color: Theme.accent
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.editor !== null
        cursorShape: Qt.OpenHandCursor
        preventStealing: true

        onPressed: mouse => {
            root.editor.beginDrag(root.atom);
            root.editor.dragTo(mapToItem(root.editor, mouse.x, mouse.y));
        }
        onPositionChanged: mouse => {
            if (pressed)
                root.editor.dragTo(mapToItem(root.editor, mouse.x, mouse.y));
        }
        onReleased: root.editor.endDrag()
        onCanceled: root.editor.cancelDrag()
    }
}
