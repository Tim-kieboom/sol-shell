import Quickshell
import QtQuick
import QtQuick.Layouts
import "./components"
import "./components/indicators"
import "../utils"
import "../singletons"

// The status bar: one window along the top of a monitor. Left: power menu and
// workspaces. Middle: media controls, volume and the clock. Right: CPU, memory
// and connectivity (wifi and bluetooth).
// qmllint disable uncreatable-type
PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 30
    color: Theme.withOpacity(Theme.shellBackground, 0.8)

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
        Spacer { size: 1 }
        VolumeIndicator {}
        Spacer { size: 5 }
        Clock {}
        FillSpace {}
        CpuIndicator {}
        MemoryIndicator {}
        Spacer { size: 10 }
        Connectivity {}
        Spacer { size: 2 }
        NotificationBell {}
        Spacer { size: 10 }
    }
}
