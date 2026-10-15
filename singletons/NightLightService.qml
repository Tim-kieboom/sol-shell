pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// The night light: a warmer color on every screen, for the evening. It is hyprsunset, a program that
// keeps the screens at a color temperature for as long as it runs and puts them back when it stops;
// so "on" means "hyprsunset is running", and the shell starts it and stops it.
//
// Whether it is on is saved (Settings.nightLight), so it is on again after the shell restarts. The
// temperature is Settings.nightLightTemperature, 4000 K unless you changed it in settings.json.
//
// hyprsunset is not stopped when the shell is: a warm screen that stays warm if the shell
// crashes or restarts is better than one that flashes cold. So starting it first stops any
// hyprsunset of yours that is still running (one left over from before, or another copy), which
// also avoids two of them fighting over the colors.
//
// If hyprsunset stops by itself (it is not installed, or another program already controls the
// colors), it is switched off here too, with a red card saying so: a switch must not say "on"
// while the screen is not warm.
//
// For a keybind:
//
//     sol-shell ipc call nightlight toggle      (or `on`, `off`)
//     sol-shell ipc call nightlight status      prints "on 4000" or "off"
Singleton {
    id: root

    readonly property bool enabled: Settings.nightLight
    // kept to what hyprsunset can show: 1000 K is deep orange, 6500 K is the screen as it is
    readonly property int temperature: Math.max(1000, Math.min(6500, Settings.nightLightTemperature))

    readonly property string status: enabled ? "on " + temperature : "off"

    function setEnabled(on: bool): void {
        Settings.nightLight = on;
    }

    function toggle(): void {
        setEnabled(!enabled);
    }

    // true while we are the ones stopping it (to turn it off, or to change the temperature), so
    // that the program ending is not taken for a failure
    property bool stopping: false

    Process {
        id: sunset

        // The command line of the program is matched from its start (not just its name): on NixOS
        // it can be a wrapper. After it is stopped the new one waits a moment, so that the old
        // one has let go of the colors. The temperature is an argument, not part of the script.
        command: ["sh", "-c", "pkill -u \"$(id -u)\" -f '^([^ ]*/)?\\.?hyprsunset(-wrapped)?( |$)' && sleep 0.5; exec hyprsunset --temperature \"$1\"", "sh", String(root.temperature)]
        running: root.enabled

        onExited: (code, status) => {
            if (root.stopping) {
                root.stopping = false;
                return;
            }
            // it ended while it was supposed to run
            if (root.enabled) {
                Settings.nightLight = false;
                ShellMessages.error("Night light", "hyprsunset stopped", "The night light is off. Is hyprsunset installed, and not already running?", "nightlight");
            }
        }
    }

    // A new temperature needs the program started again: it takes the temperature on its command line.
    onTemperatureChanged: {
        if (sunset.running) {
            stopping = true;
            sunset.running = false;
            restart.start();
        }
    }

    Timer {
        id: restart
        interval: 300
        // `running` is bound to `enabled`, which is still true, so this starts it again
        onTriggered: sunset.running = root.enabled
    }

    IpcHandler {
        target: "nightlight"

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
