import QtQuick
import "../../../singletons"

// One small vertical bar per processor thread, filled from the bottom to that
// thread's use, in the same green / accent / red as the rings in the bar. This is
// the "all the cores at once" view of htop.
Grid {
    columns: 16
    spacing: 3

    Repeater {
        // A plain number as the model makes the bars ONCE and keeps them; only
        // their values change every second. (A list of values as the model would
        // rebuild all 32 bars on every update.)
        model: SystemMonitorService.cpuThreads

        Rectangle {
            id: bar

            required property int index
            // what this thread is doing right now (0 until the first reading)
            readonly property real value: SystemMonitorService.cores[index] ?? 0

            width: 14
            height: 26
            radius: 3
            color: Theme.surface

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                // always a sliver, so an idle thread still shows as a bar
                height: Math.max(2, parent.height * bar.value)
                radius: parent.radius
                color: Theme.usageColor(bar.value)
            }
        }
    }
}
