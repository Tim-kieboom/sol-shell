import QtQuick
import "../singletons"

// A button for one bar style. `entry` is one item of BarStyle.styleList: { id, label }.
Rectangle {
    id: root

    required property var entry
    // what is picked, even when the style could not be used (then the bar shows the minimalist one)
    readonly property bool selected: Settings.barStyle === entry.id

    implicitWidth: 100
    implicitHeight: 34
    radius: 10
    color: Theme.surface
    border.width: selected ? 2 : 1
    border.color: selected ? Theme.accent : Theme.surfaceBorder

    Text {
        anchors.centerIn: parent
        text: root.entry.label
        color: Theme.primaryText
        font.family: Fonts.bodyFontFamily
        font.pixelSize: Fonts.labelMedium
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        // Writing the setting is all it takes: it is saved, and BarStyle (a binding on it)
        // redraws every bar in the new style straight away.
        onClicked: Settings.barStyle = root.entry.id
    }
}
