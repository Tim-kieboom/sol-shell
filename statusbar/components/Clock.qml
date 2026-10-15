import Quickshell
import QtQuick
import "../../singletons"
import "./calendar"

// Date and time for the middle of the bar. Updates once a minute. Clicking it opens
// the calendar popup. Compact (see the bar styles): only the time.
Item {
    id: root

    // only the time (set by the bar style)
    property bool compact: false

    implicitWidth: text.implicitWidth
    implicitHeight: text.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        id: text
        color: Theme.secondaryText
        font.pixelSize: Fonts.bodyMedium
        font.family: Fonts.bodyFontFamily
        text: Qt.formatDateTime(clock.date, root.compact ? "HH:mm" : "HH:mm " + Icons.dot + " dddd d-MMM-yyyy")
    }

    // On top of the text, so a click on it reaches it.
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
