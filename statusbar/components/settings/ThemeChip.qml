import QtQuick
import "../../../singletons"

// A button for one theme. `entry` is one item of Theme.themes: { id, label, palette }.
Rectangle {
    id: root

    required property var entry
    readonly property bool selected: Settings.themeName === entry.id

    implicitWidth: 100
    implicitHeight: 54
    radius: 10

    // The chip is painted in the theme's OWN colors, not the active theme's, so
    // it works as a little preview of what you will get.
    color: entry.palette.foregroundColor
    border.width: selected ? 2 : 1
    border.color: selected ? entry.palette.accentColor : entry.palette.searchBorderColor

    Column {
        anchors.centerIn: parent
        spacing: 6

        // three dots: the theme's accent, success and danger colors
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4

            Repeater {
                model: [root.entry.palette.accentColor, root.entry.palette.successColor, root.entry.palette.dangerColor]

                Rectangle {
                    required property color modelData
                    width: 10
                    height: 10
                    radius: 5
                    color: modelData
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.entry.label
            color: root.entry.palette.textColor
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.labelMedium
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        // Writing the setting is all it takes: it is saved to disk, and Theme
        // (a binding on it) switches every color in the shell.
        onClicked: Settings.themeName = root.entry.id
    }
}
