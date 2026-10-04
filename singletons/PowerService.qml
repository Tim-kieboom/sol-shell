pragma Singleton

import Quickshell

// The actions in the power menu (shut down, restart, log out) and the
// click-twice confirmation that guards them.
Singleton {
    // The menu is described as data: one entry per action. The popup just
    // loops over this list, so adding "Suspend" later is one new line here and
    // no UI changes at all.
    readonly property var actions: [
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
            command: ["hyprctl", "dispatch", "exit"]
        }
    ]

    // id of the action waiting for its second click, or "" if none
    property string pendingId: ""

    // First click arms the action, second click on the same one runs it.
    // Clicking a different action moves the "armed" state to that one.
    function activate(action: var): void {
        if (pendingId === action.id) {
            pendingId = "";
            // execDetached starts the command and lets go of it, so it keeps
            // running even while our own shell is being shut down
            Quickshell.execDetached(action.command);
        } else {
            pendingId = action.id;
        }
    }

    function cancel(): void {
        pendingId = "";
    }
}
