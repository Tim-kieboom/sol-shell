import QtQuick
import "../../singletons"
import "./calendar"
import "./indicators"

// The temperature next to the clock. It has no popup of its own yet: clicking it
// opens the calendar popup, which shows the weather underneath. It hides itself
// when there is no weather to show.
Item {
    id: root

    visible: indicator.visible
    implicitWidth: indicator.implicitWidth
    implicitHeight: indicator.implicitHeight

    WeatherIndicator {
        id: indicator
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.toggle()
    }

    // hangs below this item (BarPopup uses its parent as the anchor)
    BarPopup {
        id: popup
        popupWidth: 340

        CalendarPopup {}
    }
}
