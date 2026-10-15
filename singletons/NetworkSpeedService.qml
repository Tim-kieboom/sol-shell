pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// How fast data is going in and out right now, for the network speed item of the bar: what a
// download or an upload makes of the connection, in bytes per second.
//
// It reads /proc/net/dev, which has a counter of everything each network interface has sent and
// received since it came up; the speed is how much the counters grew since the last reading. All
// real interfaces are added up. Not counted: the loopback (programs talking to themselves), the
// bridges and virtual cables docker and virtual machines make, and VPN tunnels (what goes through
// them also goes through the real interface, so it would count twice).
//
// It only reads while an item shows it (`viewerCount`, see NetworkSpeed.qml): a hidden item costs
// nothing.
Singleton {
    id: root

    // how many items are showing the speed (one per monitor)
    property int viewerCount: 0

    // bytes per second
    property real downSpeed: 0
    property real upSpeed: 0
    // false until two readings have been made: one reading says nothing about a speed
    property bool known: false

    // interfaces that are not a real connection (see above)
    readonly property var ignored: /^(lo|docker|br-|veth|virbr|vmnet|tun|tap|tailscale|wg|zt|ifb)/

    // 1234567 -> "1.2 MB/s", 800 -> "800 B/s". Always the same few characters wide.
    function formatRate(bytesPerSecond: real): string {
        const kib = bytesPerSecond / 1024;
        if (kib < 1)
            return Math.round(bytesPerSecond) + " B/s";
        if (kib < 1000)
            return (kib < 10 ? kib.toFixed(1) : Math.round(kib)) + " KB/s";
        const mib = kib / 1024;
        if (mib < 1000)
            return (mib < 10 ? mib.toFixed(1) : Math.round(mib)) + " MB/s";
        return (mib / 1024).toFixed(1) + " GB/s";
    }

    property real _prevDown: -1
    property real _prevUp: -1
    property real _prevTime: 0

    function parse(contents: string): void {
        let down = 0;
        let up = 0;
        // two header lines, then "  eth0: <8 numbers received> <8 numbers sent>"
        for (const line of contents.split("\n").slice(2)) {
            const colon = line.indexOf(":");
            if (colon < 0)
                continue;
            const name = line.slice(0, colon).trim();
            if (ignored.test(name))
                continue;
            const f = line.slice(colon + 1).trim().split(/\s+/).map(Number);
            down += f[0] || 0;
            up += f[8] || 0;
        }
        const now = Date.now();
        if (_prevTime > 0 && now > _prevTime) {
            const seconds = (now - _prevTime) / 1000;
            // an interface that went away takes its counter with it: the total drops, which is no speed
            downSpeed = Math.max(0, down - _prevDown) / seconds;
            upSpeed = Math.max(0, up - _prevUp) / seconds;
            known = true;
        }
        _prevDown = down;
        _prevUp = up;
        _prevTime = now;
    }

    // Reading starts with the first item and stops with the last. The old readings are thrown away
    // when it stops: the first speed after a pause would be an average over the whole pause.
    onViewerCountChanged: {
        if (viewerCount === 0) {
            _prevTime = 0;
            known = false;
            downSpeed = 0;
            upSpeed = 0;
        }
    }

    FileView {
        id: netFile
        path: "/proc/net/dev"
        onLoaded: root.parse(text())
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.viewerCount > 0
        triggeredOnStart: true
        onTriggered: netFile.reload()
    }
}
