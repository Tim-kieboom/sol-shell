pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// CPU and memory usage, read from /proc every 2 seconds. The usage values are
// fractions from 0.0 to 1.0.
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

    // Reading a file is much cheaper than starting a program (cat, head) to read
    // it, and we do this every 2 seconds, so FileView is used here and not Process.
    // The files are re-read on the timer below; `loaded` fires when the new
    // contents are in.
    FileView {
        id: memoryFile
        path: "/proc/meminfo"
        onLoaded: root.parseMemory(text())
    }

    FileView {
        id: cpuFile
        path: "/proc/stat"
        onLoaded: root.parseCpu(text())
    }

    // meminfo has lines like "MemTotal:       32843620 kB"
    function parseMemory(contents: string): void {
        const total = contents.match(/^MemTotal:\s+(\d+)/m);
        const available = contents.match(/^MemAvailable:\s+(\d+)/m);
        if (total)
            totalKiB = Number(total[1]);
        if (available)
            availableKiB = Number(available[1]);
    }

    function parseCpu(contents: string): void {
        // The first line is the total over all cores (the cpu0, cpu1, ... lines
        // follow it): "cpu  user nice system idle iowait irq softirq steal ..."
        const f = contents.split("\n", 1)[0].trim().split(/\s+/).slice(1, 9).map(Number);
        const idle = f[3] + f[4];                       // idle + iowait
        const total = f.reduce((a, b) => a + b, 0);

        const dTotal = total - _prevTotal;
        const dIdle = idle - _prevIdle;

        // skip the very first reading: _prev* is still 0, so the
        // delta would be "all time since boot"
        if (_prevTotal > 0 && dTotal > 0)
            cpuUsage = (dTotal - dIdle) / dTotal;

        _prevTotal = total;
        _prevIdle = idle;
    }

    // Re-read both files every 2 seconds
    Timer {
        interval: 2000
        // the files load once by themselves when the shell starts, so the first
        // timer tick (2s in) gives the second cpu reading right away
        running: true
        repeat: true
        onTriggered: {
            memoryFile.reload();
            cpuFile.reload();
        }
    }
}
