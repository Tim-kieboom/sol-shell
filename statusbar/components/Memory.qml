import QtQuick
import "../../singletons"
import "./indicators"
import "./taskmanager"

// The memory ring in the bar. It has no popup of its own yet: clicking it opens the
// same task manager as the CPU ring (its own copy, anchored to this ring; only one
// popup can be open at a time because of the focus grab).
Item {
    id: root

    implicitWidth: indicator.implicitWidth
    implicitHeight: indicator.implicitHeight

    // see Cpu.qml
    Component.onDestruction: {
        if (popup.open)
            SystemMonitorService.viewerCount -= 1;
    }

    MemoryIndicator {
        id: indicator
        onClicked: popup.toggle()
    }

    BarPopup {
        id: popup

        alignRight: true
        popupWidth: 380

        onOpenChanged: SystemMonitorService.viewerCount += open ? 1 : -1

        TaskManager {}
    }
}
