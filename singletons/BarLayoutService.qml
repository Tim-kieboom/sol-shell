pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../utils/layoutMove.js" as Move

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

    // ---- changing it (the editor in the settings) ----

    // whether your own layout is in use
    readonly property bool active: layout !== null

    // The text of a layout file: one line for each side, so it is easy to read and to edit by hand.
    function format(data: var): string {
        const line = list => JSON.stringify(list).replace(/,/g, ", ");
        return "{\n  \"left\": " + line(data.left) + ",\n  \"center\": " + line(data.center) + ",\n  \"right\": " + line(data.right) + "\n}\n";
    }

    // Writes a layout as the file: the whole of it, to a temporary file that then replaces it, so the
    // watcher (this one) never reads half of it. The folder is made if it is not there. Only a layout
    // that passes the check is written: the editor can never leave you with a file that is not used.
    function save(data: var): bool {
        const complete = { left: data.left ?? [], center: data.center ?? [], right: data.right ?? [] };
        const problems = check(complete);
        if (problems.length > 0) {
            console.warn("sol-shell: not saving the bar layout: " + problems.join("; "));
            return false;
        }
        writer.command = ["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1.tmp\" && mv \"$1.tmp\" \"$1\"", "sh", path, format(complete)];
        writer.running = true;
        return true;
    }

    // The layout of the style in use, as plain names and lists of names (what the file holds): the
    // starting point of "Customize". The normal layout, not the compact one: the compact bar is made
    // from your layout by taking items out.
    function styleLayout(style: var): var {
        const plain = entry => typeof entry === "string" ? entry : entry.atom;
        const side = list => (list ?? []).map(entry => Array.isArray(entry) ? entry.map(plain) : plain(entry));
        return { left: side(style.sections.left), center: side(style.sections.center), right: side(style.sections.right) };
    }

    // creates the file from the layout the style draws now
    function customize(): void {
        save(styleLayout(BarStyle.current));
    }

    // Moves an item to a place in your layout (see utils/layoutMove.js for what a target is) and saves it.
    function move(name: string, target: var): void {
        if (!layout)
            return;
        const next = Move.moved(layout, name, target);
        if (next)
            save(next);
    }

    // Takes an item out of your layout: it is then put at its default place, like any item the layout
    // does not list.
    function unplace(name: string): void {
        if (!layout)
            return;
        const next = Move.removed(layout, name);
        if (next)
            save(next);
    }

    // ---- presets and layouts you save ----

    // Ready-made arrangements (only the arrangement: no bar style, compact or position). Two are the
    // layouts the styles come with; the other is made here. Items a preset does not list are added at
    // their default place like with any layout.
    readonly property var presets: [
        { id: "minimal", label: "Minimal style", layout: styleLayout(BarStyle.styles.minimal) },
        { id: "islands", label: "Islands style", layout: styleLayout(BarStyle.styles.islands) },
        {
            id: "dashboard",
            label: "Dashboard",
            layout: {
                left: [["power", "launcher"], ["workspaces"]],
                center: [["clock", "weather"], "media"],
                right: [["cpu", "memory", "disk"], ["volume", "wifi", "bluetooth"], ["tray"], ["updates", "vpn", "privacy", "battery", "powerMode", "bell", "settings"]]
            }
        }
    ]

    function applyPreset(layoutOfPreset: var): void {
        save(layoutOfPreset);
    }

    // The layouts you saved are files in this folder, one for each name.
    readonly property string savedDir: Settings.homeDir + "/.config/quickshell/bar-layouts"
    // their names, sorted
    property var saved: []

    // a name that is safe to use as a file name: letters, digits, spaces, - and _, up to 40
    function validName(name: string): bool {
        return /^[A-Za-z0-9][A-Za-z0-9 _-]{0,39}$/.test(name);
    }

    function refreshSaved(): void {
        if (!lister.running)
            lister.running = true;
    }

    // Saves your layout under a name (replacing one of the same name). False if there is no layout in
    // use or the name cannot be used.
    function saveAs(name: string): bool {
        if (!layout || !validName(name))
            return false;
        // the name is an argument of the command, not part of it, so it is never read as shell
        saver.command = ["sh", "-c", "mkdir -p \"$1\" && printf '%s' \"$3\" > \"$1/$2.json.tmp\" && mv \"$1/$2.json.tmp\" \"$1/$2.json\"", "sh", savedDir, name, format(layout)];
        saver.running = true;
        return true;
    }

    // makes a saved layout the one in use (after checking it like the layout file itself)
    function applySaved(name: string): void {
        if (!validName(name))
            return;
        applier.command = ["cat", savedDir + "/" + name + ".json"];
        applier.running = true;
    }

    function deleteSaved(name: string): void {
        if (!validName(name))
            return;
        remover.command = ["rm", "-f", savedDir + "/" + name + ".json"];
        remover.running = true;
    }

    Process {
        id: lister
        command: ["sh", "-c", "for f in \"$1\"/*.json; do [ -e \"$f\" ] && basename \"$f\" .json; done; true", "sh", root.savedDir]
        stdout: StdioCollector {
            onStreamFinished: root.saved = text.split("\n").filter(name => root.validName(name)).sort()
        }
    }

    Process {
        id: saver
        onExited: root.refreshSaved()
    }

    Process {
        id: remover
        onExited: root.refreshSaved()
    }

    Process {
        id: applier
        // `cat` fails when there is no such file
        onExited: code => {
            if (code !== 0)
                ShellMessages.error("Bar layout", "No such saved layout", "There is no saved layout called " + applier.command[1].split("/").pop().replace(".json", "") + ".", "bar-layout-saved");
        }
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    const problems = root.check(data);
                    if (problems.length === 0)
                        root.save(data);
                    else
                        ShellMessages.error("Bar layout", "That saved layout cannot be used", problems.join("; ") + ".", "bar-layout-saved");
                } catch (e) {
                    ShellMessages.error("Bar layout", "That saved layout cannot be used", "It is not valid JSON.", "bar-layout-saved");
                }
            }
        }
    }

    // deletes the file: back to the style's own layout
    function reset(): void {
        writer.command = ["rm", "-f", path];
        writer.running = true;
    }

    Process {
        id: writer
        // the watcher notices the new file too; reading it at once makes the editor follow without waiting
        onExited: file.reload()
    }

    FileView {
        id: file
        path: root.path
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.apply(text())
        // no file (or it was deleted): the style's own layout
        onLoadFailed: root.apply("")
    }

    // a preset that is not a usable layout is a mistake in this file: say so
    Component.onCompleted: {
        for (const preset of presets) {
            const problems = check(preset.layout);
            if (problems.length > 0)
                console.error("sol-shell: the bar layout preset " + preset.id + " is broken: " + problems.join("; "));
        }
    }

    // for checking from a terminal: sol-shell ipc call barlayout status
    IpcHandler {
        target: "barlayout"

        // `list`: the presets and the layouts you saved, by name
        function list(): string {
            root.refreshSaved();
            return "presets: " + root.presets.map(p => p.id).join(", ") + "\nsaved: " + (root.saved.length > 0 ? root.saved.join(", ") : "none");
        }

        // `apply minimal` or `apply "my layout"`: a preset or a saved layout becomes the layout in use
        function apply(name: string): string {
            const preset = root.presets.find(p => p.id === name);
            if (preset) {
                root.applyPreset(preset.layout);
                return "applying preset " + name;
            }
            if (!root.validName(name))
                return "no preset called " + name + ", and it cannot be the name of a saved layout";
            root.applySaved(name);
            return "applying " + name + " (a card says if there is no such layout, or it cannot be used)";
        }

        // `save "my layout"`: keeps the layout in use under that name
        function save(name: string): string {
            return root.saveAs(name) ? "saved " + name : "not saved (a layout must be in use, and the name only letters, digits, spaces, - and _)";
        }

        function remove(name: string): string {
            if (!root.validName(name))
                return name + " cannot be the name of a saved layout";
            root.deleteSaved(name);
            return "deleting " + name;
        }

        function status(): string {
            if (root.problem !== "")
                return "not used: " + root.problem;
            return root.layout ? "in use: " + JSON.stringify(root.layout) : "none (the style's own layout)";
        }
    }
}
