import Quickshell
import QtQuick
import QtQuick.Layouts
import "./components"
import "./components/indicators"
import "../utils"
import "../singletons"

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
        Rectangle {
            width: 1
        }
        VolumeIndicator {}
        Rectangle {
            width: 5
        }
        Clock {}
        FillSpace {}
        CpuIndicator {}
        MemoryIndicator {}
        Rectangle {
            width: 10
        }
        Connectivity {}
        Rectangle {
            width: 10
        }
    }
}
