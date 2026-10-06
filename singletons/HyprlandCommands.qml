pragma Singleton

import Quickshell

// Asking Hyprland to do something (switch workspace, end the session) with
// `hyprctl dispatch`. Hyprland 0.55 added Lua config files, and a Hyprland that runs
// one only accepts the new spelling (`hl.dsp.focus({ ... })`), while every older
// Hyprland, and one started from a hyprland.conf, only accepts the classic one
// (`workspace 3`). hyprctl prints "ok" when it accepted the request, so each command
// below tries the new spelling and, if that is not accepted, the classic one.
Singleton {
    id: root

    // $1 is the new spelling; the rest are the classic dispatcher and its arguments.
    // Nothing is pasted into the script text: the values arrive as arguments.
    readonly property string script: 'out=$(hyprctl dispatch "$1" 2>&1); [ "$out" = ok ] || { shift; hyprctl dispatch "$@"; }'

    // the command to run (a list, for Process or execDetached)
    function dispatchCommand(lua: string, classic: var): var {
        return ["sh", "-c", script, "sh", lua].concat(classic);
    }

    function focusWorkspace(id: int): void {
        Quickshell.execDetached(dispatchCommand('hl.dsp.focus({ workspace = "' + id + '" })', ["workspace", String(id)]));
    }

    readonly property var logoutCommand: dispatchCommand("hl.dsp.exit()", ["exit"])
}
