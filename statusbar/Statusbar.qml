import Quickshell
import QtQuick
import QtQuick.Layouts
import "./components"
import "./components/indicators"
import "../utils"
import "../singletons"

// The status bar: one window along the top of a monitor. Left: power menu and
// workspaces. Middle: media controls, volume, and the clock with the temperature.
// Right: CPU, memory, wifi and bluetooth.
// qmllint disable uncreatable-type
PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 30
    color: Theme.withOpacity(Theme.shellBackground, Settings.backgroundOpacity)

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10

        PowerMenu {}
        Workspace {
            screenName: root.screen.name
        }
        FillSpace {}
        Media {}
        Spacer {
            size: 1
        }
        VolumeIndicator {}
        Spacer {
            size: 5
        }
        Clock {}
        Weather {
            // the old clock-and-temperature item put 14 between them; the layout gives 5
            Layout.leftMargin: 9
        }
        FillSpace {}
        Cpu {}
        Memory {}
        Spacer {
            size: 10
        }
        ColorPicker {
            screenName: root.screen.name
        }
        Spacer {
            size: 2
        }
        Wifi {}
        Bluetooth {
            // the old connectivity item put 8 between its two icons; the layout gives 5
            Layout.leftMargin: 3
        }
        Spacer {
            size: 2
        }
        NotificationBell {}
        Spacer {
            size: 10
        }
    }
}
