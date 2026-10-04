import Quickshell.Hyprland
import QtQuick

import "../../singletons"

// Hyprland workspace buttons, followed by the name of this bar's monitor.
// Click a workspace to switch to it.
Row {
    id: root
    spacing: 6
    required property string screenName

    Repeater {
        model: Hyprland.workspaces

        Rectangle {
            required property var modelData

            width: 24
            height: 20
            radius: 4
            color: modelData.focused ? Theme.accent : Theme.surface

            Text {
                anchors.centerIn: parent
                text: parent.modelData.id
                color: parent.modelData.focused ? Theme.accentText : Theme.primaryText
                font.family: Fonts.bodyFontFamily
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = \"" + parent.modelData.id + "\" })")
            }
        }
    }

    Rectangle {
        width: label.implicitWidth + 8
        height: 20
        radius: 4
        color: Theme.surface

        Text {
            id: label
            anchors.centerIn: parent
            text: root.screenName
            color: Theme.primaryText
            font.family: Fonts.bodyFontFamily
        }
    }
}
