pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

// The keyboard layout Hyprland is using ("us", "nl"), and a way to switch to the next one. The
// layouts are the ones in Hyprland's own configuration (`kb_layout = "us,nl"`); with one layout
// there is nothing to switch to, and clicking does nothing.
//
// How it knows: `hyprctl devices -j` lists the keyboards with their layouts (a comma separated
// list), the variants that go with them and the number of the one in use. That is asked again
// whenever Hyprland says the layout changed (the `activelayout` event) or its configuration was
// read again. Switching asks Hyprland to switch every keyboard, so they stay the same.
//
// It can be used from a keybind too:
//
//     sol-shell ipc call keyboard next        (or `previous`)
//     sol-shell ipc call keyboard current     prints for example "US"
Singleton {
    id: root

    // [{ code: "us", variant: "" }, { code: "nl", variant: "" }, ...], in Hyprland's order
    property var layouts: []
    // the number of the one in use, in `layouts`
    property int index: 0

    readonly property int count: layouts.length
    readonly property var current: layouts[index] ?? null
    // what the bar shows: "US", or "US intl" for a variant
    readonly property string label: current ? current.code.toUpperCase() + (current.variant !== "" ? " " + current.variant : "") : ""

    // Ask Hyprland. The main keyboard is the one that counts: all keyboards are kept the same.
    //
    // Hyprland says "the layout changed" once for every keyboard it switched, and the answer is
    // only right once it has switched them all. So the events are bunched together: the question
    // is asked a moment after the last one. A question that is still being answered when another
    // is due is not dropped: it is asked again straight after.
    function refresh(): void {
        settle.restart();
    }

    property bool askAgain: false

    Timer {
        id: settle
        interval: 60
        onTriggered: {
            if (query.running)
                root.askAgain = true;
            else
                query.running = true;
        }
    }

    function next(): void {
        switchTo("next");
    }

    function previous(): void {
        switchTo("prev");
    }

    function switchTo(which: string): void {
        if (count < 2)
            return;
        // `hyprctl switchxkblayout` is a command of its own, not a dispatcher, so it is the same
        // in a Lua configuration and in the older hyprland.conf
        Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", which]);
    }

    Component.onCompleted: query.running = true

    // Hyprland says "activelayout>>keyboard,Layout name" when a layout changes, and
    // "configreloaded" after the configuration was read again (a new `kb_layout`).
    Connections {
        target: Hyprland

        function onRawEvent(event: var): void {
            if (event.name === "activelayout" || event.name === "configreloaded")
                root.refresh();
        }
    }

    Process {
        id: query

        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.parse(text);
                if (root.askAgain) {
                    root.askAgain = false;
                    query.running = true;
                }
            }
        }
    }

    function parse(json: string): void {
        let keyboards = [];
        try {
            keyboards = JSON.parse(json).keyboards ?? [];
        } catch (e) {
            console.warn("sol-shell: cannot read the keyboards from hyprctl (the layout is not shown):", e);
            return;
        }
        const main = keyboards.find(k => k.main) ?? keyboards[0];
        if (!main)
            return;
        const codes = main.layout.split(",");
        const variants = (main.variant ?? "").split(",");
        layouts = codes.map((code, i) => ({
                    code: code.trim(),
                    variant: (variants[i] ?? "").trim()
                }));
        index = Math.max(0, Math.min(codes.length - 1, main.active_layout_index ?? 0));
    }

    IpcHandler {
        target: "keyboard"

        function next(): void {
            root.next();
        }

        function previous(): void {
            root.previous();
        }

        function current(): string {
            return root.label;
        }
    }
}
