import QtQuick
import "../singletons"

// A button for one item of the bar: lit while the item is shown, dim while it is hidden. `atom`
// is the item's name (see BarStyle.atomNames). The settings item is always shown, so its chip
// does nothing.
Rectangle {
    id: root

    required property string atom

    readonly property bool locked: root.atom === BarStyle.requiredAtom
    readonly property bool shown: !BarStyle.isHidden(root.atom)

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 28
    radius: height / 2
    color: shown ? Theme.surface : "transparent"
    border.width: shown ? 2 : 1
    border.color: shown ? Theme.accent : Theme.surfaceBorder
    // the settings item cannot be switched off: its chip is drawn quieter
    opacity: locked ? 0.6 : 1.0

    Text {
        id: label
        anchors.centerIn: parent
        text: BarStyle.atomLabels[root.atom] ?? root.atom
        color: root.shown ? Theme.primaryText : Theme.mutedText
        font.family: Fonts.bodyFontFamily
        font.pixelSize: Fonts.labelMedium
    }

    MouseArea {
        anchors.fill: parent
        enabled: !root.locked
        cursorShape: root.locked ? Qt.ArrowCursor : Qt.PointingHandCursor
        // Writing the setting is all it takes: it is saved, and the renderer (a binding on it)
        // takes the item out of the bar, or puts it back, at once.
        onClicked: BarStyle.setHidden(root.atom, root.shown)
    }
}
