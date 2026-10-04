pragma Singleton

import Quickshell
import Quickshell.Bluetooth

Singleton {
    // The bluetooth controller (the chip in your PC); null if there is none
    readonly property var adapter: Bluetooth.defaultAdapter

    readonly property bool available: adapter !== null
    readonly property bool enabled: available && adapter.enabled

    readonly property var connectedDevices: Bluetooth.devices.values.filter(d => d.connected)

    // "paired" = you have set this device up before (headphones, mouse, ...),
    // as opposed to every device that merely happens to be nearby.
    readonly property var pairedDevices: Bluetooth.devices.values.filter(d => d.paired)

    // Devices only tell us a freedesktop icon *name* like "audio-headphones".
    // We turn that into one of our own glyphs; anything unknown gets the
    // generic bluetooth icon.
    function iconFor(device: var): string {
        const name = device.icon ?? "";
        if (name.includes("headset") || name.includes("headphones"))
            return Icons.headphones;
        if (name.includes("speaker") || name.includes("audio"))
            return Icons.speaker;
        if (name.includes("mouse"))
            return Icons.mouse;
        if (name.includes("keyboard"))
            return Icons.keyboard;
        if (name.includes("phone"))
            return Icons.phone;
        if (name.includes("gaming") || name.includes("joystick"))
            return Icons.gamepad;
        return Icons.bluetooth;
    }

    // One line for the UI: "Connected · 30%", "Connecting...", "Not connected"
    function deviceStatus(device: var): string {
        if (device.state === BluetoothDeviceState.Connecting)
            return "Connecting...";
        if (device.state === BluetoothDeviceState.Disconnecting)
            return "Disconnecting...";
        if (!device.connected)
            return "Not connected";
        return device.batteryAvailable
            ? "Connected · " + Math.round(device.battery * 100) + "%"
            : "Connected";
    }

    // A click means "flip it": connect if disconnected, disconnect if connected
    function toggleConnection(device: var): void {
        if (device.connected)
            device.disconnect();
        else
            device.connect();
    }

    readonly property string statusText: {
        if (!enabled)
            return "Off";
        if (connectedDevices.length === 0)
            return "On";
        if (connectedDevices.length === 1)
            return connectedDevices[0].name;
        return connectedDevices.length + " connected";
    }

    function toggle(): void {
        if (adapter)
            adapter.enabled = !adapter.enabled;
    }
}
