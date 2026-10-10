pragma Singleton

import Quickshell
import Quickshell.Io

// The actions in the power menu (lock, suspend, shut down, restart, log out) and the
// click-twice confirmation that guards the ones that end your session. If an action
// fails, the shell says so.
Singleton {
    // The menu is described as data: one entry per action. The popup just
    // loops over this list. An entry with `confirm: false` runs on the first click
    // (nothing is lost by locking or suspending); the others ask for a second click.
    readonly property var actions: [
        {
            id: "lock",
            label: "Lock",
            icon: Icons.lock,
            confirm: false
        },
        {
            id: "suspend",
            label: "Suspend",
            icon: Icons.sleep,
            confirm: false
        },
        {
            id: "poweroff",
            label: "Shut down",
            icon: Icons.power,
            command: ["systemctl", "poweroff"]
        },
        {
            id: "reboot",
            label: "Restart",
            icon: Icons.restart,
            command: ["systemctl", "reboot"]
        },
        {
            id: "logout",
            label: "Log out",
            icon: Icons.logout,
            // asks Hyprland to end the session
            command: HyprlandCommands.logoutCommand
        }
    ]

    // id of the action waiting for its second click, or "" if none
    property string pendingId: ""

    // First click arms the action, second click on the same one runs it.
    // Clicking a different action moves the "armed" state to that one.
    function activate(action: var): void {
        if (pendingId === action.id) {
            pendingId = "";
            run(action.command, action.label);
        } else {
            pendingId = action.id;
        }
    }

    function cancel(): void {
        pendingId = "";
    }

    // Runs an entry that needs no confirmation: locking and suspending are the lock
    // service's job, everything else is a command.
    function perform(action: var): void {
        if (action.id === "lock")
            LockService.lock();
        else if (action.id === "suspend")
            LockService.suspend();
        else
            run(action.command, action.label);
    }

    // Runs a command, and tells you when it fails (for example when you are not
    // allowed to shut down) instead of failing without a word. `label` is for the
    // message: "Could not shut down".
    function run(command: var, label: string): void {
        if (runner.running)
            return;
        runner.label = label;
        runner.exitCode = 0;
        runner.exited = false;
        runner.errorRead = false;
        runner.command = command;
        runner.running = true;
    }

    Process {
        id: runner

        property string label: ""
        property int exitCode: 0
        // The exit code and the error text arrive separately, in either order. The
        // message is made once both are in.
        property bool exited: false
        property bool errorRead: false

        stderr: StdioCollector {
            id: errors
            onStreamFinished: {
                runner.errorRead = true;
                runner.reportIfFailed();
            }
        }

        onExited: code => {
            exitCode = code;
            exited = true;
            reportIfFailed();
        }

        function reportIfFailed(): void {
            if (!exited || !errorRead || exitCode === 0)
                return;
            const details = errors.text.trim();
            ShellMessages.error("Power", "Could not " + label.toLowerCase(),
                details !== "" ? details : "The command failed (exit code " + exitCode + ").", "power");
        }
    }
}
