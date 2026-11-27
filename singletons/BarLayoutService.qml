pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Your own layout of the bar, from ~/.config/quickshell/bar-layout.json. Without the file the
// bar is drawn as the style lays it out; with it, you decide which items sit on the left, in the
// center and on the right, and which are grouped into pills:
//
//   {
//     "left":   ["power", "launcher", ["workspaces"]],
//     "center": [["clock", "weather"]],
//     "right":  [["cpu", "memory"], "volume", "wifi", "settings"]
//   }
//
// An entry is an item's name, or a list of names: a pill (an island). BarStyle.mergedSections
// works out the rest: the items the file does not list are added back where the style has them
// by default, and the compact bar is applied on top.
//
// The file is watched, so a change shows within a moment, without a restart. A file that cannot
// be used (not JSON, an item that does not exist, an item twice) is not used at all: the bar is
// drawn as the style lays it out, and a card says what is wrong.
Singleton {
    id: root

    readonly property string path: Settings.homeDir + "/.config/quickshell/bar-layout.json"

    // { left, center, right } when a usable file exists, otherwise null
    property var layout: null
    // what is wrong with the file; empty when it is fine or not there
    property string problem: ""

    // Checks a layout that came out of JSON: the problems found, none when it can be used.
    function check(data: var): var {
        const problems = [];
        if (typeof data !== "object" || data === null || Array.isArray(data))
            return ["the file must hold an object with left, center and right"];
        for (const key of Object.keys(data)) {
            if (!["left", "center", "right"].includes(key))
                problems.push("\"" + key + "\" is not left, center or right");
        }
        const seen = [];
        const checkName = (name, part) => {
            if (typeof name !== "string" || !BarStyle.atomNames.includes(name)) {
                problems.push("there is no item " + JSON.stringify(name) + " (in " + part + "; the items are " + BarStyle.atomNames.join(", ") + ")");
                return;
            }
            if (seen.includes(name))
                problems.push(name + " is listed twice");
            seen.push(name);
        };
        for (const part of ["left", "center", "right"]) {
            if (data[part] === undefined)
                continue;
            if (!Array.isArray(data[part])) {
                problems.push(part + " must be a list");
                continue;
            }
            for (const entry of data[part]) {
                if (Array.isArray(entry)) {
                    if (entry.length === 0)
                        problems.push(part + " has an empty pill");
                    for (const name of entry) {
                        if (Array.isArray(name))
                            problems.push(part + " has a pill inside a pill");
                        else
                            checkName(name, part);
                    }
                } else {
                    checkName(entry, part);
                }
            }
        }
        return problems;
    }

    // Takes what the file holds ("" for no file). Sets `layout` and `problem`, and says so in a card
    // when the file is broken (once for each different problem).
    function apply(contents: string): void {
        if (contents.trim() === "") {
            layout = null;
            problem = "";
            return;
        }
        let problems;
        let data = null;
        try {
            data = JSON.parse(contents);
            problems = check(data);
        } catch (e) {
            problems = ["it is not valid JSON (" + e.message + ")"];
        }
        if (problems.length === 0) {
            problem = "";
            layout = {
                left: data.left ?? [],
                center: data.center ?? [],
                right: data.right ?? []
            };
            return;
        }
        layout = null;
        const text = problems.join("; ");
        if (text !== problem) {
            problem = text;
            console.warn("sol-shell: bar-layout.json cannot be used: " + text);
            ShellMessages.error("Bar layout", "bar-layout.json cannot be used", text + ". The bar is drawn with the default layout.", "bar-layout");
        }
    }

    FileView {
        path: root.path
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.apply(text())
        // no file (or it was deleted): the style's own layout
        onLoadFailed: root.apply("")
    }

    // for checking from a terminal: sol-shell ipc call barlayout status
    IpcHandler {
        target: "barlayout"

        function status(): string {
            if (root.problem !== "")
                return "not used: " + root.problem;
            return root.layout ? "in use: " + JSON.stringify(root.layout) : "none (the style's own layout)";
        }
    }
}
