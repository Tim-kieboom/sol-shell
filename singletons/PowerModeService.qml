pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick

// The power mode of the machine (power saver, balanced, performance), which is what
// power-profiles-daemon switches. The item of the bar shows the one in use and a click lists the
// three. Performance is not offered where the machine has none (`hasPerformance`).
//
//     sol-shell ipc call powermode status                       "balanced"
//     sol-shell ipc call powermode set power-saver              (or balanced, performance)
Singleton {
    id: root

    // The modes, in the order they are listed. `value` is UPower's number for it.
    readonly property var modes: [
        {
            id: "power-saver",
            value: PowerProfile.PowerSaver,
            title: "Power saver",
            subtitle: "Longer battery, slower",
            icon: Icons.powerSaver
        },
        {
            id: "balanced",
            value: PowerProfile.Balanced,
            title: "Balanced",
            subtitle: "A bit of both",
            icon: Icons.balanced
        },
        {
            id: "performance",
            value: PowerProfile.Performance,
            title: "Performance",
            subtitle: "Faster, uses more power",
            icon: Icons.performance
        }
    ]

    readonly property bool hasPerformance: PowerProfiles.hasPerformanceProfile
    readonly property var available: modes.filter(m => m.id !== "performance" || hasPerformance)

    readonly property int profile: PowerProfiles.profile
    readonly property var current: modes.find(m => m.value === profile) ?? modes[1]

    function set(mode: var): void {
        PowerProfiles.profile = mode.value;
    }

    // the daemon says when it holds the performance mode back
    readonly property string degradedText: {
        if (PowerProfiles.degradationReason === PerformanceDegradationReason.LapDetected)
            return "Performance is held back: the machine is on a lap";
        if (PowerProfiles.degradationReason === PerformanceDegradationReason.HighTemperature)
            return "Performance is held back: the machine is hot";
        return "";
    }

    IpcHandler {
        target: "powermode"

        function status(): string {
            return root.current.id;
        }

        function set(name: string): string {
            const mode = root.available.find(m => m.id === name);
            if (!mode)
                return "unknown mode " + name + " (one of " + root.available.map(m => m.id).join(", ") + ")";
            root.set(mode);
            return mode.id;
        }
    }
}
