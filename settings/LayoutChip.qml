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

    // The one option this item has, if it has one: the clock and the media controls can be compact, the
    // workspaces can show the name of their monitor. Shown as a small badge you can click, on placed chips
    // of the editor only.
    readonly property var option: root.editor !== null && !root.dim ? ({
            clock: { key: "compact", label: "compact", fallback: false },
            media: { key: "compact", label: "compact", fallback: false },
            workspaces: { key: "monitorName", label: "name", fallback: Settings.showMonitorName }
        })[root.atom] : undefined
    readonly property bool optionOn: root.option !== undefined && (BarLayoutService.layout?.options?.[root.atom]?.[root.option.key] ?? root.option.fallback)

    implicitWidth: label.implicitWidth + 20 + (option !== undefined ? badge.width + 6 : 0)
    implicitHeight: 26
    radius: height / 2
    color: dim ? "transparent" : Theme.surface
    border.width: 1
    border.color: dim ? Theme.surfaceBorder : Theme.accent
    opacity: beingDragged ? 0.3 : (dim ? 0.7 : 1.0)

    Text {
        id: label
        x: 10
        anchors.verticalCenter: parent.verticalCenter
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

    // the option of the item, a small switch on its chip: lit while it is on
    Rectangle {
        id: badge
        visible: root.option !== undefined
        x: label.x + label.implicitWidth + 6
        anchors.verticalCenter: parent.verticalCenter
        width: badgeLabel.implicitWidth + 12
        height: 18
        radius: 9
        color: root.optionOn ? Theme.accent : "transparent"
        border.width: 1
        border.color: root.optionOn ? Theme.accent : Theme.surfaceBorder

        Text {
            id: badgeLabel
            anchors.centerIn: parent
            text: root.option !== undefined ? root.option.label : ""
            color: root.optionOn ? Theme.accentText : Theme.mutedText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.labelSmall
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            preventStealing: true
            onClicked: BarLayoutService.setOption(root.atom, root.option.key, !root.optionOn)
        }
    }
}
