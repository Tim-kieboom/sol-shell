pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // ---- RAM (from /proc/meminfo) ----
    property real totalKiB: 0
    property real availableKiB: 0
    readonly property real usedKiB: Math.max(0, totalKiB - availableKiB)
    readonly property real usage: totalKiB > 0 ? usedKiB / totalKiB : 0
    readonly property string usedFormatted: (usedKiB / 1048576).toFixed(1) + "G"

    // ---- CPU (from /proc/stat) ----
    // 0.0 - 1.0, same scale as `usage` above
    property real cpuUsage: 0
    readonly property string cpuFormatted: Math.round(cpuUsage * 100) + "%"

    // /proc/stat only holds counters that grow forever, so one reading is
    // meaningless. Usage = how much they changed since the previous reading.
    property real _prevTotal: 0
    property real _prevIdle: 0

    Process {
        id: memoryInfoReader
        command: ["cat", "/proc/meminfo"]
        stdout: SplitParser {
            onRead: data => {
                const fields = data.trim().split(/\s+/);
                if (fields[0] === "MemTotal:")
                    root.totalKiB = Number(fields[1]);
                else if (fields[0] === "MemAvailable:")
                    root.availableKiB = Number(fields[1]);
            }
        }
    }

    Process {
        id: cpuReader
        // first line only: the aggregate "cpu" line (not cpu0, cpu1, ...)
        command: ["head", "-n1", "/proc/stat"]
        stdout: SplitParser {
            onRead: data => {
                // "cpu  user nice system idle iowait irq softirq steal ..."
                const f = data.trim().split(/\s+/).slice(1, 9).map(Number);
                const idle = f[3] + f[4];                       // idle + iowait
                const total = f.reduce((a, b) => a + b, 0);

                const dTotal = total - root._prevTotal;
                const dIdle = idle - root._prevIdle;

                // skip the very first reading: _prev* is still 0, so the
                // delta would be "all time since boot"
                if (root._prevTotal > 0 && dTotal > 0)
                    root.cpuUsage = (dTotal - dIdle) / dTotal;

                root._prevTotal = total;
                root._prevIdle = idle;
            }
        }
    }

    // One timer drives both readers (memory and cpu)
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            // guard: don't restart a process that is still running
            if (!memoryInfoReader.running)
                memoryInfoReader.running = true;
            if (!cpuReader.running)
                cpuReader.running = true;
        }
    }
}
