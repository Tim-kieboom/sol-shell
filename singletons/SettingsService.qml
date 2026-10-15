pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Whether the settings window is open. The window itself is settings/SettingsWindow.qml;
// this is the one switch everything uses: the settings button in the bar, the Settings row
// in the power menu, and the command line.
//
//     sol-shell ipc call settings open
//
// The command line is what makes the settings reachable whatever the bar looks like: a bar
// style without a settings button can still be switched back from a keybind.
Singleton {
    id: root

    property bool open: false

    function show(): void {
        open = true;
    }

    function close(): void {
        open = false;
    }

    function toggle(): void {
        open = !open;
    }

    IpcHandler {
        target: "settings"

        function open(): void {
            root.show();
        }

        function close(): void {
            root.close();
        }

        function toggle(): void {
            root.toggle();
        }
    }
}
