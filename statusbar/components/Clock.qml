import Quickshell
import QtQuick
import "../../singletons"

// Date and time for the middle of the bar. Updates once a minute.
Text {

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    color: Theme.secondaryText
    font.pixelSize: Fonts.bodyMedium
    font.family: Fonts.bodyFontFamily
    text: Qt.formatDateTime(clock.date, "HH:mm " + Icons.dot + " dddd d-MMM-yyyy")
}
