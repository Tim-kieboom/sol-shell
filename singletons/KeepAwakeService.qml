pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Keeps the screen from locking and switching off while it is on, for the keep-awake item of the
// bar. It is a Wayland idle inhibitor (idle/KeepAwakeInhibitor.qml): the compositor then does not
// report the user as idle, so hypridle (and anything else that waits for idle time) does not fire.
// A program that ignores the protocol, or hypridle with `ignore_wayland_inhibit` on, is not held off.
//
// The state is saved (Settings.keepAwake), so it is still on after the shell restarts. There is no
// timer: it stays on until switched off.
Singleton {
    id: root

    readonly property bool enabled: Settings.keepAwake

    function setEnabled(on: bool): void {
        Settings.keepAwake = on;
    }

    function toggle(): void {
        setEnabled(!enabled);
    }

    readonly property string status: "keepawake: " + (enabled ? "on" : "off")

    IpcHandler {
        target: "keepawake"

        function toggle(): void {
            root.toggle();
        }

        function on(): void {
            root.setEnabled(true);
        }

        function off(): void {
            root.setEnabled(false);
        }

        function status(): string {
            return root.status;
        }
    }
}
