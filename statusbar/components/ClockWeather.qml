import QtQuick
import "../../singletons"
import "./calendar"
import "./indicators"

// The clock and the temperature next to it. Clicking either one opens the
// calendar popup (with the weather underneath).
Item {
    id: root

    implicitWidth: content.width
    implicitHeight: content.height

    Row {
        id: content

        spacing: 14

        Clock {
            anchors.verticalCenter: parent.verticalCenter
        }

        WeatherIndicator {
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // On top of the content, so a click on the text or the icon reaches it.
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
