pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// How long the computer has been on, for the uptime item of the bar. /proc/uptime holds the seconds
// since boot; it is read every half minute, which is enough for a figure shown in minutes.
Singleton {
    id: root

    property real seconds: 0
    // "7h 46m", "1d 1h"
    readonly property string text: SystemMonitorService.formatUptime(seconds)
    // when it was switched on
    readonly property date bootTime: new Date(clock.date.getTime() - seconds * 1000)

    // the time, so that bootTime is worked out against the same clock as the rest of the bar
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    FileView {
        id: file
        path: "/proc/uptime"
        // "27987.43 215083.76": seconds since boot, and idle seconds of all threads added
        onLoaded: root.seconds = Number(text().split(" ")[0]) || 0
    }

    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: file.reload()
    }
}
