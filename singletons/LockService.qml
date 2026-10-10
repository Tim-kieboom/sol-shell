pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import QtQuick

// Locking the screen, and suspending with the screen locked.
//
// The lock itself is made by the compositor (Wayland's ext-session-lock protocol): while
// it is on, nothing else can be seen or clicked, whatever the shell does. This singleton
// holds what the lock screen shows (see lock/LockScreen.qml) and checks the password with
// PAM, the same way login does.
//
//     sol-shell ipc call lock lock        lock now (also what the power menu does)
//     sol-shell ipc call lock suspend     lock, then suspend: waking up asks for the password
//     sol-shell ipc call lock locked      true or false
//
// A lock you cannot open would be worse than no lock, so the screen is only locked when
// the PAM service named below exists (see `canLock`). On NixOS the module creates it.
Singleton {
    id: root

    // true while the screen should be locked. lock/SessionLock.qml turns this into the real
    // lock, and sets it back to false if the compositor ends the lock by itself.
    property bool locked: false
    // true once the compositor confirms that every screen is covered (set by SessionLock)
    property bool secure: false

    // what has been typed into the password field, on whichever monitor
    property string typed: ""
    // shown under the field: "" or why the last try failed
    property string error: ""
    // true while PAM is checking a password
    property bool checking: false

    // PAM looks for /etc/pam.d/<pamService>
    readonly property string pamService: "sol-shell"
    readonly property string pamFile: "/etc/pam.d/" + pamService

    // ---------------------------------------------------------------- locking

    // set by suspend(): suspend as soon as the lock is on
    property bool suspendWhenLocked: false

    function lock(): void {
        if (locked || guard.running)
            return;
        guard.running = true;
    }

    function suspend(): void {
        if (locked) {
            suspendNow();
            return;
        }
        suspendWhenLocked = true;
        lock();
    }

    // Checks that PAM can open the lock again before it is closed: a missing service would
    // leave you with a screen nobody can unlock.
    Process {
        id: guard
        command: ["test", "-r", root.pamFile]
        onExited: code => {
            if (code === 0) {
                root.typed = "";
                root.error = "";
                root.checking = false;
                root.locked = true;
            } else {
                root.suspendWhenLocked = false;
                ShellMessages.error("Lock", "Cannot lock the screen",
                    "There is no PAM service " + root.pamFile + ", so there would be no way to unlock it. See the README.", "lock-pam");
            }
        }
    }

    // suspend only once the compositor says the screens are covered, so waking up shows the
    // lock screen and never the session
    onSecureChanged: {
        if (secure && suspendWhenLocked) {
            suspendWhenLocked = false;
            // a moment for the lock screen to be drawn
            suspendTimer.restart();
        }
    }

    onLockedChanged: {
        if (!locked) {
            suspendWhenLocked = false;
            typed = "";
            error = "";
            pam.abort();
        }
    }

    Timer {
        id: suspendTimer
        interval: 400
        onTriggered: root.suspendNow()
    }

    function suspendNow(): void {
        Quickshell.execDetached(["systemctl", "suspend"]);
    }

    // ------------------------------------------------------------- password

    function submit(): void {
        if (checking || typed === "")
            return;
        checking = true;
        error = "";
        if (!pam.start()) {
            checking = false;
            error = "Could not check the password";
        }
    }

    PamContext {
        id: pam
        config: root.pamService

        // PAM asks for the password: answer with what was typed
        onPamMessage: {
            if (responseRequired) {
                respond(root.typed);
                root.typed = "";
            }
        }

        onCompleted: result => {
            root.checking = false;
            root.typed = "";
            if (result === PamResult.Success) {
                root.error = "";
                root.locked = false;
            } else if (result === PamResult.MaxTries) {
                root.error = "Too many tries, wait a moment";
            } else if (result === PamResult.Failed) {
                root.error = "Wrong password";
            } else {
                root.error = "Could not check the password";
            }
        }

        onError: e => {
            root.checking = false;
            root.typed = "";
            root.error = "Could not check the password (" + PamError.toString(e) + ")";
        }
    }

    // ------------------------------------------------------------- ipc control

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lock();
        }

        function suspend(): void {
            root.suspend();
        }

        function locked(): bool {
            return root.locked;
        }

        // why the last try failed ("Wrong password"), or an empty line
        function error(): string {
            return root.error;
        }
    }
}
