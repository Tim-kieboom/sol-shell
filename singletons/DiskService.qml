pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// How full the disks are, for the disk item of the bar. It asks `df` once a minute (a disk does not
// fill up faster than that, and the figure is only useful to a whole percent).
//
// `disks` is a list with one entry per disk that holds files: { mount, source, size, used, avail,
// fraction } in bytes, the fraction used from 0.0 to 1.0 (like df's Use%: of what can be used). The one
// with the system on it (the mount `/`) comes first, and is also `main`. Memory-backed and virtual file
// systems are left out, and a disk that is mounted in several places (NixOS binds /nix/store onto the
// root) is listed once.
Singleton {
    id: root

    property var disks: []
    readonly property var main: disks.length > 0 ? disks[0] : null

    // above this a disk is nearly full, and the bar says so
    readonly property real warnFraction: 0.9

    // 63744000000 -> "59.4 GiB"
    function formatBytes(bytes: real): string {
        const gib = bytes / 1073741824;
        if (gib >= 1024)
            return (gib / 1024).toFixed(1) + " TiB";
        if (gib >= 10)
            return Math.round(gib) + " GiB";
        if (gib >= 1)
            return gib.toFixed(1) + " GiB";
        return Math.round(bytes / 1048576) + " MiB";
    }

    function refresh(): void {
        if (!df.running)
            df.running = true;
    }

    // "Filesystem 1-blocks Used Available Capacity Mounted on", then one line per file system
    function parse(contents: string): void {
        const seen = {};
        const list = [];
        for (const line of contents.split("\n").slice(1)) {
            const f = line.trim().split(/\s+/);
            if (f.length < 6)
                continue;
            const mount = f.slice(5).join(" ");
            // not the disks of the system itself, nor what a container runtime or a sandbox mounts
            if (/^\/(run|sys|proc|dev|var\/lib\/docker|var\/lib\/containers|nix\/store)(\/|$)/.test(mount))
                continue;
            if (seen[f[0]])
                continue;
            seen[f[0]] = true;
            const size = Number(f[1]);
            const used = Number(f[2]);
            const avail = Number(f[3]);
            // as df says "Use%": of what a program may use, not of the reserve root keeps too
            if (!(used + avail > 0))
                continue;
            list.push({
                mount: mount,
                source: f[0],
                size: size,
                used: used,
                avail: avail,
                fraction: Math.min(1, used / (used + avail))
            });
        }
        // the system disk first, the rest in the order df gave them
        list.sort((a, b) => (b.mount === "/") - (a.mount === "/"));
        disks = list;
    }

    Timer {
        interval: 60000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: df
        command: ["df", "-P", "-B1", "-x", "tmpfs", "-x", "devtmpfs", "-x", "squashfs", "-x", "overlay", "-x", "ramfs", "-x", "efivarfs", "-x", "fuse.portal", "-x", "fuse.gvfsd-fuse"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }
}
