import QtQuick
import "../singletons"

// One item of the bar, drawn as a small chip in the layout editor: the item's name for people
// ("Wi-Fi"). Dimmed when the item is not placed by your layout.
Rectangle {
    id: root

    required property string atom
    property bool dim: false

    implicitWidth: label.implicitWidth + 20
    implicitHeight: 26
    radius: height / 2
    color: dim ? "transparent" : Theme.surface
    border.width: 1
    border.color: dim ? Theme.surfaceBorder : Theme.accent
    opacity: dim ? 0.7 : 1.0

    Text {
        id: label
        anchors.centerIn: parent
        text: BarStyle.atomLabels[root.atom] ?? root.atom
        color: root.dim ? Theme.mutedText : Theme.primaryText
        font.family: Fonts.bodyFontFamily
        font.pixelSize: Fonts.labelMedium
    }
}
