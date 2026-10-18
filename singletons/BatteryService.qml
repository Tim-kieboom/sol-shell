pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick

// The battery, for the battery item of the bar and its popup. It is UPower's "display device": one
// battery that stands for all the batteries of the machine. A desktop has none, so there is
// nothing to show there (`present` is false and the items hide themselves).
//
//     sol-shell ipc call battery status      for example "87% discharging, 3h 10m left (raw 0.87)"
//
// The raw number is in the status so it can be checked: Quickshell gives the charge as a fraction
// from 0 to 1, and this multiplies it by 100.
Singleton {
    id: root

    readonly property var device: UPower.displayDevice

    // false on a machine without a battery (or while UPower has not answered yet)
    readonly property bool present: device !== null && device.ready && device.isPresent

    // 0 to 100
    readonly property int percent: present ? Math.max(0, Math.min(100, Math.round(device.percentage * 100))) : 0

    // plugged in and charging; and plugged in at all (a full battery on mains is not "charging")
    readonly property bool charging: present && device.state === UPowerDeviceState.Charging
    readonly property bool full: present && device.state === UPowerDeviceState.FullyCharged
    readonly property bool onMains: !UPower.onBattery

    // running low while it is not being charged
    readonly property bool low: present && !charging && !onMains && percent <= 15

    readonly property string icon: {
        if (!present)
            return Icons.batteryUnknown;
        if (low && percent <= 5)
            return Icons.batteryAlert;
        // 0-9 is the first glyph (10%), 100 the last
        const index = Math.max(0, Math.min(9, Math.round(percent / 10) - 1));
        return (charging || full ? Icons.batteryChargingLevels : Icons.batteryLevels)[index];
    }

    readonly property string statusText: {
        if (!present)
            return "No battery";
        if (charging)
            return "Charging";
        if (full)
            return "Fully charged";
        if (device.state === UPowerDeviceState.Discharging)
            return "On battery";
        if (device.state === UPowerDeviceState.PendingCharge || device.state === UPowerDeviceState.PendingDischarge)
            return onMains ? "Plugged in, not charging" : "Waiting";
        return onMains ? "Plugged in" : "On battery";
    }

    // 11400 (seconds) -> "3h 10m"; 0 means UPower does not know
    function formatSeconds(seconds: real): string {
        if (!(seconds > 0))
            return "";
        const minutes = Math.round(seconds / 60);
        const hours = Math.floor(minutes / 60);
        return hours > 0 ? hours + "h " + (minutes % 60) + "m" : minutes + "m";
    }

    // "3h 10m left", "40m until full", or "" when it is not known
    readonly property string timeText: {
        if (!present)
            return "";
        if (charging) {
            const t = formatSeconds(device.timeToFull);
            return t === "" ? "" : t + " until full";
        }
        if (!onMains) {
            const t = formatSeconds(device.timeToEmpty);
            return t === "" ? "" : t + " left";
        }
        return "";
    }

    // watts going in or out right now, "" when not known
    readonly property string powerText: present && device.changeRate !== 0 ? Math.abs(device.changeRate).toFixed(1) + " W" : ""

    readonly property string status: present ? percent + "% " + statusText.toLowerCase() + (timeText !== "" ? ", " + timeText : "") + " (raw " + device.percentage + ")" : "no battery"

    IpcHandler {
        target: "battery"

        function status(): string {
            return root.status;
        }
    }
}
