import Quickshell.Hyprland
import QtQuick

import "../../singletons"

// Hyprland workspace buttons, followed by the name of this bar's monitor (unless the settings
// say not to show it). Click a workspace to switch to it.
Row {
    // this monitor's colors
    readonly property var theme: Theme.forScreen(Window.window?.screen?.name ?? "")
    id: root
    spacing: 6
    required property string screenName

    // whether the monitor's name is shown after the numbers: the setting, unless a layout says otherwise
    property bool showName: Settings.showMonitorName

    Repeater {
        model: Hyprland.workspaces

        Rectangle {
            required property var modelData

            width: 24
            height: 20
            radius: 4
            color: modelData.focused ? theme.accent : theme.surface

            Text {
                anchors.centerIn: parent
                text: parent.modelData.id
                color: parent.modelData.focused ? theme.accentText : theme.primaryText
                font.family: Fonts.bodyFontFamily
            }

            MouseArea {
                anchors.fill: parent
                onClicked: HyprlandCommands.focusWorkspace(parent.modelData.id)
            }
        }
    }

    // the monitor's name; a hidden item in a Row takes no space, so nothing is left of it
    Rectangle {
        visible: root.showName
        width: label.implicitWidth + 8
        height: 20
        radius: 4
        color: theme.surface

        Text {
            id: label
            anchors.centerIn: parent
            text: root.screenName
            color: theme.primaryText
            font.family: Fonts.bodyFontFamily
        }
    }
}
