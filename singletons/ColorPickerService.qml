pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Picks a color from anywhere on the screen with hyprpicker: the screen freezes, you
// click a pixel, and the hex code (#rrggbb) of that pixel is shown in a popup under the
// eyedropper in the bar (see ColorPicker.qml). Escape cancels without a word.
//
//     sol-shell ipc call picker pick     (the bar's eyedropper does the same)
//     sol-shell ipc call picker last     (prints the last color picked)
//
// hyprpicker must be installed; the Nix package puts it on the shell's PATH. When it is
// missing, a red card says so.
Singleton {
    id: root

    // true while hyprpicker is waiting for your click
    property bool picking: false
    // the last color picked, "#rrggbb", or "" when none yet
    property string lastColor: ""

    // emitted when a color has been picked: the bar shows it
    signal picked(string color)

    function pick(): void {
        if (picking)
            return;
        picking = true;
        picker.exited = false;
        picker.streamDone = false;
        picker.output = "";
        picker.running = true;
    }

    // "#c8a96a" if `text` holds a hex color, else ""
    function parseColor(text: string): string {
        const match = text.match(/#[0-9a-fA-F]{6}\b/);
        return match ? match[0].toLowerCase() : "";
    }

    function finished(code: int, output: string): void {
        picking = false;
        if (code === 127) {
            ShellMessages.error("Color picker", "hyprpicker is not installed", "Install hyprpicker to pick colors from the screen.", "picker-missing");
            return;
        }
        const color = parseColor(output);
        // no color: you pressed Escape (hyprpicker exits without one), nothing to report
        if (code !== 0 || color === "")
            return;
        lastColor = color;
        picked(color);
    }

    Process {
        id: picker

        // The exit code and the output arrive separately, in either order; the result is
        // handled once both are in.
        property bool exited: false
        property bool streamDone: false
        property int exitCode: 0
        property string output: ""

        // `command -v` first: a missing hyprpicker gives 127, which says so in the card.
        // Nothing is pasted into the script text.
        command: ["sh", "-c", "command -v hyprpicker >/dev/null || exit 127; exec hyprpicker --no-fancy --format=hex --lowercase-hex --quiet"]

        stdout: StdioCollector {
            onStreamFinished: {
                picker.output = text;
                picker.streamDone = true;
                picker.done();
            }
        }

        onExited: code => {
            exitCode = code;
            exited = true;
            done();
        }

        function done(): void {
            if (exited && streamDone) {
                exited = false;
                streamDone = false;
                root.finished(exitCode, output);
            }
        }
    }

    // Lets a Hyprland keybind (or a script) start the picker:
    //   sol-shell ipc call picker pick
    IpcHandler {
        target: "picker"

        function pick(): void {
            root.pick();
        }

        // the last color picked, or an empty line
        function last(): string {
            return root.lastColor;
        }
    }
}
