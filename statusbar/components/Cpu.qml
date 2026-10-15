import QtQuick
import "../../singletons"
import "./indicators"
import "./taskmanager"

// The CPU ring in the bar. Clicking it opens the task manager: a small popup with
// what htop and btop show.
Item {
    id: root

    implicitWidth: indicator.implicitWidth
    implicitHeight: indicator.implicitHeight

    // If this bar disappears while its popup is open (a monitor is unplugged), the
    // popup's close never fires, so give back its +1 here (see below).
    Component.onDestruction: {
        if (popup.open)
            SystemMonitorService.viewerCount -= 1;
    }

    CpuIndicator {
        id: indicator
        onClicked: popup.toggle()
    }

    // hangs below the ring (this Item is the anchor item)
    BarPopup {
        id: popup

        // at the right end of the bar: grow leftwards
        alignRight: true
        popupWidth: 380

        // Tell the service how many popups are open: it reads /proc only while at
        // least one is. Fires once per open and once per close.
        onOpenChanged: SystemMonitorService.viewerCount += open ? 1 : -1

        TaskManager {}
    }
}
