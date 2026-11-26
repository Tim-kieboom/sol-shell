pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Which VPNs are up, for the VPN item of the bar. It looks at the network interfaces the kernel
// lists in /sys/class/net, and an interface counts as a VPN when its kernel type says WireGuard or
// PPP, or when its name is one the VPN programs use (tun0, tailscale0, wg0, zt..., nordlynx, ...).
// "Up" is the interface's UP flag, not its state: a working WireGuard interface says "unknown".
//
// It only looks while an item shows it (`viewerCount`, see Vpn.qml). Programs name their interfaces
// as they like, so a VPN with an odd name that is not WireGuard is not found.
Singleton {
    id: root

    // how many items are showing it (one per monitor)
    property int viewerCount: 0

    // the VPNs that are up: [{ name: "wg0", kind: "WireGuard" }, ...]
    property var active: []
    readonly property bool anyActive: active.length > 0

    // names of VPN interfaces, with what to call them. (Not `tap`: virtual machines make those.)
    readonly property var namePatterns: [
        { pattern: /^tailscale/, kind: "Tailscale" },
        { pattern: /^wg/, kind: "WireGuard" },
        { pattern: /^nordlynx|^proton|^mullvad/, kind: "WireGuard" },
        { pattern: /^zt/, kind: "ZeroTier" },
        { pattern: /^tun/, kind: "VPN tunnel" },
        { pattern: /^ppp/, kind: "PPP" },
        { pattern: /^(ipsec|vti|xfrm)/, kind: "IPsec" }
    ]

    // What kind of VPN an interface is, or "" when it is not one. `devtype` is the DEVTYPE line of the
    // interface's uevent file ("wireguard", "ppp", or nothing).
    function kindOf(name: string, devtype: string): string {
        if (devtype === "wireguard")
            return "WireGuard";
        if (devtype === "ppp")
            return "PPP";
        const found = namePatterns.find(entry => entry.pattern.test(name));
        return found ? found.kind : "";
    }

    // `contents` is one line per interface: name, flags (hex, as the kernel writes them) and DEVTYPE
    // (empty or "wireguard"), separated by tabs. Bit 0 of the flags is "up".
    function parse(contents: string): var {
        const found = [];
        for (const line of contents.split("\n")) {
            const parts = line.split("\t");
            if (parts.length < 2 || parts[0] === "")
                continue;
            const name = parts[0];
            const up = (parseInt(parts[1], 16) & 1) === 1;
            const kind = kindOf(name, (parts[2] ?? "").replace("DEVTYPE=", "").trim());
            if (up && kind !== "")
                found.push({ name: name, kind: kind });
        }
        return found.sort((a, b) => a.name.localeCompare(b.name));
    }

    // a line of text for scripts: "vpn: wg0 (WireGuard), tailscale0 (Tailscale)" or "vpn: none"
    readonly property string status: "vpn: " + (anyActive ? active.map(v => v.name + " (" + v.kind + ")").join(", ") : "none")

    // One small read of the list: a line for every interface. No quoting trouble: nothing in it comes
    // from outside, and the names are only printed.
    Process {
        id: reader
        command: [
            "sh", "-c",
            "for d in /sys/class/net/*; do printf '%s\\t%s\\t%s\\n' \"${d##*/}\" \"$(cat \"$d/flags\" 2>/dev/null)\" \"$(grep -h '^DEVTYPE=' \"$d/uevent\" 2>/dev/null)\"; done"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const now = root.parse(text);
                // only replace the list when it changed, so the item does not redraw every few seconds
                if (JSON.stringify(now) !== JSON.stringify(root.active))
                    root.active = now;
            }
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: root.viewerCount > 0
        triggeredOnStart: true
        onTriggered: {
            if (!reader.running)
                reader.running = true;
        }
    }

    // nothing is known while nothing is looking
    onViewerCountChanged: {
        if (viewerCount === 0)
            active = [];
    }

    IpcHandler {
        target: "vpn"

        function status(): string {
            return root.status;
        }
    }
}
