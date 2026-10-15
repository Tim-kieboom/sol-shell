pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// The application launcher (wofi, by default) behind the launcher button in the bar. One click
// opens it, the next closes it: a launcher is a program of its own, so "closing" it means stopping
// that program. It works the same from the command line, for a keybind:
//
//     sol-shell ipc call launcher toggle
//
// The command is Settings.launcherCommand. The program is found by the start of its command
// line (its first word, without its folder), so a launcher started some other way, from a keybind
// of your own, is closed by the button too. On NixOS wofi is a wrapper whose process is called
// `.wofi-wrapped`, and process names are cut at 15 characters, so its name could not be used.
Singleton {
    id: root

    readonly property string command: Settings.launcherCommand

    // the program's name: "wofi" for "wofi --show drun ...", "rofi" for "/usr/bin/rofi -show drun"
    readonly property string programName: command.trim().split(/\s+/)[0].split("/").pop()

    // A pattern for pkill -f that matches the start of the command line of that program, with or
    // without its folder, as a Nix wrapper (`.wofi-wrapped`) or not, followed by its arguments or
    // nothing. Anchored at the start so that a program that merely has the name somewhere in its
    // arguments (an editor with wofi.css open) is not hit.
    readonly property string pattern: "^([^ ]*/)?\\.?" + programName.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "(-wrapped)?( |$)"

    // Close the launcher if it is running (pkill says so with its exit status), start it if not.
    // The pattern and the command are passed as arguments, not written into the script, so
    // nothing in them is ever read as shell code by this script (the command itself is run by
    // a shell, so `~` and quotes work in it). Only your own programs are closed.
    function toggle(): void {
        if (programName === "")
            return;
        Quickshell.execDetached(["sh", "-c", "pkill -u \"$(id -u)\" -f \"$1\" || exec sh -c \"$2\"", "sh", pattern, command]);
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.toggle();
        }
    }
}
