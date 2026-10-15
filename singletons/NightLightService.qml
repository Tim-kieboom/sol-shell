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
// It can switch itself on and off by the clock (Settings.nightLightSchedule, with the times
// Settings.nightLightFrom and nightLightUntil). The schedule decides when it starts and when it ends:
// at those times, when it is switched on in the settings, and when the shell starts, the night light is
// set to what the schedule says. In between you can still switch it by hand; the schedule takes over
// again at its next time.
//
// For a keybind:
//
//     sol-shell ipc call nightlight toggle      (or `on`, `off`)
//     sol-shell ipc call nightlight status      prints "on 4000" or "off"
Singleton {
    id: root

    // Whether it is on. It starts as what was saved, and from then on it is the service that
    // decides: a switch by hand (which is saved, so it is the same next time) or the schedule (which
    // is not saved: the schedule works it out again whenever the shell starts). The schedule must not
    // write the settings: it runs when the settings were just read, and a write made then can lose a
    // race with the file being read again, and come back as the old value.
    property bool active: Settings.nightLight
    readonly property bool enabled: active
    // kept to what hyprsunset can show: 1000 K is deep orange, 6500 K is the screen as it is
    readonly property int temperature: Math.max(1000, Math.min(6500, Settings.nightLightTemperature))

    readonly property string status: enabled ? "on " + temperature : "off"

    // by hand: the choice is saved
    function setEnabled(on: bool): void {
        active = on;
        Settings.nightLight = on;
    }

    function toggle(): void {
        setEnabled(!enabled);
    }

    // ---- the schedule ----

    // "21:00" -> 1260 (minutes since midnight), or -1 when it is not a time of day
    function minutesOf(text: string): int {
        const match = /^(\d{1,2}):(\d{2})$/.exec((text ?? "").trim());
        if (!match)
            return -1;
        const hours = parseInt(match[1]);
        const minutes = parseInt(match[2]);
        return hours < 24 && minutes < 60 ? hours * 60 + minutes : -1;
    }

    // minutes since midnight as "07:05"
    function timeText(minutes: int): string {
        const wrapped = (minutes % 1440 + 1440) % 1440;
        return String(Math.floor(wrapped / 60)).padStart(2, "0") + ":" + String(wrapped % 60).padStart(2, "0");
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property int fromMinutes: minutesOf(Settings.nightLightFrom)
    readonly property int untilMinutes: minutesOf(Settings.nightLightUntil)
    readonly property int nowMinutes: clock.hours * 60 + clock.minutes

    // A schedule needs two times of day that are not the same (the same two would be "never").
    readonly property bool scheduled: Settings.nightLightSchedule && fromMinutes >= 0 && untilMinutes >= 0 && fromMinutes !== untilMinutes

    // What the schedule says about right now. Past midnight when `until` is before `from`.
    readonly property bool scheduledOn: scheduled && (fromMinutes < untilMinutes ? nowMinutes >= fromMinutes && nowMinutes < untilMinutes : nowMinutes >= fromMinutes || nowMinutes < untilMinutes)

    // what the schedule said when it last set the night light: it only acts when this changes,
    // so a switch by hand lasts until the next time
    property var lastScheduled: undefined

    function followSchedule(): void {
        if (!scheduled) {
            lastScheduled = undefined;
            return;
        }
        if (scheduledOn !== lastScheduled) {
            lastScheduled = scheduledOn;
            active = scheduledOn;
        }
    }

    // The schedule acts a moment after the last change, not at once. Two settings that change
    // together (both times edited in the file) arrive one after the other, and in between the
    // schedule would be looking at a pair that was never meant, and might switch the night light on
    // or off for good.
    onScheduledOnChanged: settle.restart()
    onScheduledChanged: settle.restart()
    Component.onCompleted: {
        followSchedule();
        sync();
    }

    Timer {
        id: settle
        interval: 400
        onTriggered: root.followSchedule()
    }

    // true from the moment we ask the program to stop until it has ended, so that its ending is not
    // taken for a failure (to turn it off, or to start it again with another temperature)
    property bool stopping: false

    // Make the program run if the night light is on, and stop if it is off. Asked for whenever
    // that may have changed, and when the program has ended.
    function sync(): void {
        if (enabled && !sunset.running && !stopping) {
            sunset.running = true;
        } else if (!enabled && sunset.running && !stopping) {
            stopping = true;
            sunset.running = false;
        }
    }

    onEnabledChanged: sync()

    // A new temperature needs the program started again: it takes the temperature on its command line.
    onTemperatureChanged: {
        if (sunset.running && !stopping) {
            stopping = true;
            sunset.running = false;
        }
    }

    Process {
        id: sunset

        // The command line of the program is matched from its start (not just its name): on NixOS
        // it can be a wrapper. After it is stopped the new one waits a moment, so that the old
        // one has let go of the colors. The temperature is an argument, not part of the script.
        command: ["sh", "-c", "pkill -u \"$(id -u)\" -f '^([^ ]*/)?\\.?hyprsunset(-wrapped)?( |$)' && sleep 0.5; exec hyprsunset --temperature \"$1\"", "sh", String(root.temperature)]

        onExited: (code, status) => {
            if (root.stopping) {
                // we asked it to stop; if the night light is wanted again by now (switched off and on
                // quickly, or a new temperature), start it again
                root.stopping = false;
                root.sync();
                return;
            }
            // it ended while it was supposed to run
            if (root.enabled) {
                root.setEnabled(false);
                ShellMessages.error("Night light", "hyprsunset stopped", "The night light is off. Is hyprsunset installed, and not already running?", "nightlight");
            }
        }
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
            return root.status + (root.scheduled ? " (schedule " + root.timeText(root.fromMinutes) + " to " + root.timeText(root.untilMinutes) + ")" : "");
        }
    }
}
