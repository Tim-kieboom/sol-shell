pragma Singleton

import Quickshell
import Quickshell.Bluetooth
import QtQuick

// Bluetooth for the bar: whether the adapter is on, which paired devices there
// are and whether they are connected. Also switches Bluetooth on and off and
// connects or disconnects a device.
Singleton {
    id: root

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
        if (device.connected) {
            device.disconnect();
            return;
        }
        // Bluetooth has no "that failed" signal, so a connection attempt is watched
        // (see below) and judged by how it ends.
        attempt = device;
        sawConnecting = false;
        timeout.restart();
        device.connect();
    }

    // ---- when connecting fails ----

    // The device we are trying to connect right now, or null
    property var attempt: null
    // true once the device has reported "Connecting"; a device that then drops back
    // to "Disconnected" without having connected is a failed attempt
    property bool sawConnecting: false

    Connections {
        // a null target is simply ignored
        target: root.attempt

        function onStateChanged(): void {
            const device = root.attempt;
            if (!device)
                return;
            if (device.state === BluetoothDeviceState.Connecting)
                root.sawConnecting = true;
            else if (device.state === BluetoothDeviceState.Connected)
                root.endAttempt();
            else if (device.state === BluetoothDeviceState.Disconnected && root.sawConnecting)
                root.failAttempt(device, "did not respond");
        }
    }

    // A device that is off or out of range can leave the attempt hanging for a long
    // time: give up after a while.
    Timer {
        id: timeout
        interval: 20000
        onTriggered: {
            if (root.attempt && !root.attempt.connected)
                root.failAttempt(root.attempt, "took too long to respond");
        }
    }

    function endAttempt(): void {
        timeout.stop();
        attempt = null;
        sawConnecting = false;
    }

    function failAttempt(device: var, what: string): void {
        endAttempt();
        // `key` stops a device that keeps failing from stacking up cards
        ShellMessages.error("Bluetooth", "Could not connect",
            device.name + " " + what + ". Make sure it is switched on, in range and not "
            + "connected to something else.", "bluetooth:" + device.address);
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
