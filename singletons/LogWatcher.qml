pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Shows the shell's own warnings and errors (what `sol-shell problems` prints) as cards, for when
// something in the shell is going wrong and you would otherwise not know: an island that does not
// click, an icon that does not draw. Switched on in the settings (Settings.notifyProblems), off
// by default, because a shell on a new machine has a few harmless warnings.
//
// QML cannot read its own log, so this runs `quickshell log` on this very shell and reads the lines
// that arrive. Every message shows once, and no more than a few cards come in a row: a problem that
// repeats every frame would otherwise bury the screen. How many were held back is said once, after.
// The log has them all: `sol-shell problems`.
//
//     sol-shell ipc call problems status      "on", and how many cards were shown and held back
Singleton {
    id: root

    readonly property bool enabled: Settings.notifyProblems

    // warnings that are normal on some machines and tell you nothing you can act on
    readonly property var ignored: [/Unable to determine system time zone/, /Could not register notification server/, /Registration will be attempted again/]

    // what has been shown already (a message is shown once per session) and the counts of the
    // current stretch of ten seconds
    property var seen: ({})
    property int shownNow: 0
    property int heldBack: 0
    // for the status
    property int shownTotal: 0

    readonly property int cardsPerStretch: 4

    function handle(line: string): void {
        // colours, if the log has any
        const text = line.replace(/\x1b\[[0-9;]*m/g, "").trim();
        const warn = /^WARN\b/.test(text);
        const error = /^(ERROR|FATAL)\b/.test(text);
        if (!warn && !error)
            return;
        if (ignored.some(pattern => pattern.test(text)))
            return;
        if (seen[text])
            return;
        seen[text] = true;

        if (shownNow >= cardsPerStretch) {
            heldBack += 1;
            return;
        }
        shownNow += 1;
        shownTotal += 1;
        // "WARN qt.qpa.wayland: Failed to create ..." -> the part after the first colon is the message
        const colon = text.indexOf(":");
        const message = colon > 0 ? text.slice(colon + 1).trim() : text;
        if (error)
            ShellMessages.error("sol-shell log", "Error in the shell", message, "log-" + message.slice(0, 80));
        else
            ShellMessages.info("sol-shell log", "Warning from the shell", message, "log-" + message.slice(0, 80));
    }

    Timer {
        interval: 10000
        repeat: true
        running: root.enabled
        onTriggered: {
            if (root.heldBack > 0) {
                ShellMessages.info("sol-shell log", "More problems in the log", root.heldBack + " more, see `sol-shell problems`", "log-more");
                root.heldBack = 0;
            }
            root.shownNow = 0;
        }
    }

    // The last lines of the log, then every new one. It reads this shell's own log (by its process
    // number), so it cannot pick up another shell's. Gone when the setting is off.
    Process {
        running: root.enabled
        command: ["quickshell", "log", "--pid", String(Quickshell.processId), "-t", "300", "-f"]
        stdout: SplitParser {
            onRead: line => root.handle(line)
        }
    }

    IpcHandler {
        target: "problems"

        function status(): string {
            return (root.enabled ? "on" : "off") + ", " + root.shownTotal + " shown, " + root.heldBack + " held back";
        }
    }
}
