pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../utils/layoutMove.js" as Move

// Your own layout of the bar, from ~/.config/quickshell/bar-layout.json. Without the file the
// bar is drawn as the style lays it out; with it, the file says everything about which items are in
// the bar and where:
//
//   {
//     "version": 2,
//     "left":   ["power", "launcher", ["workspaces"]],
//     "center": [["clock", "weather"]],
//     "right":  [["cpu", "memory"], { "menu": ["volume", "wifi"] }, "settings"],
//     "options": { "clock": { "compact": true } }
//   }
//
// An entry is an item's name, a list of names (a pill, an island), or { "menu": [names] }: the
// dropdown, the three dots, with those items in its menu instead of in the bar. There is at most one,
// and for now only volume, wifi, bluetooth, colorPicker, nightLight and keepAwake can go in it.
// "options" are the settings of single items: the clock and the media controls can be "compact", and
// the workspaces can show or hide their "monitorName".
//
// An item the file does not list is not in the bar (it is hidden), except "settings", which is always
// there: it is the way back to this. BarStyle.mergedSections turns the layout into what the bar draws.
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

    // the options an item can have, and the kind of value of each: only a few items have any
    readonly property var allowedOptions: ({
            clock: ["compact"],
            media: ["compact"],
            workspaces: ["monitorName"]
        })

    // Checks a layout that came out of JSON: the problems found, none when it can be used.
    function check(data: var): var {
        const problems = [];
        if (typeof data !== "object" || data === null || Array.isArray(data))
            return ["the file must hold an object with left, center and right"];
        for (const key of Object.keys(data)) {
            if (!["version", "left", "center", "right", "options"].includes(key))
                problems.push("\"" + key + "\" is not version, left, center, right or options");
        }
        if (data.version !== undefined && data.version !== 2)
            problems.push("version is " + JSON.stringify(data.version) + ", and only 2 is known");
        const seen = [];
        let menus = 0;
        const checkName = (name, part, inMenu) => {
            if (typeof name !== "string" || !BarStyle.atomNames.includes(name)) {
                problems.push("there is no item " + JSON.stringify(name) + " (in " + part + "; the items are " + BarStyle.atomNames.join(", ") + ")");
                return;
            }
            if (inMenu && !Move.MENU_ATOMS.includes(name))
                problems.push(name + " cannot go in the dropdown yet (it takes " + Move.MENU_ATOMS.join(", ") + ")");
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
                        if (typeof name === "object" && name !== null)
                            problems.push(part + " has a pill or a dropdown inside a pill");
                        else
                            checkName(name, part, false);
                    }
                } else if (typeof entry === "object" && entry !== null) {
                    if (!Array.isArray(entry.menu) || Object.keys(entry).length !== 1) {
                        problems.push(part + " has an entry that is neither an item, a pill nor { \"menu\": [...] }");
                        continue;
                    }
                    menus += 1;
                    if (entry.menu.length === 0)
                        problems.push("the dropdown is empty");
                    for (const name of entry.menu)
                        checkName(name, part, true);
                } else {
                    checkName(entry, part, false);
                }
            }
        }
        if (menus > 1)
            problems.push("there can be only one dropdown");
        if (data.options !== undefined) {
            if (typeof data.options !== "object" || data.options === null || Array.isArray(data.options)) {
                problems.push("options must be { item: { option: value } }");
            } else {
                for (const item of Object.keys(data.options)) {
                    const allowed = allowedOptions[item];
                    if (!allowed) {
                        problems.push(item + " has no options");
                        continue;
                    }
                    const values = data.options[item];
                    if (typeof values !== "object" || values === null || Array.isArray(values)) {
                        problems.push("the options of " + item + " must be { option: value }");
                        continue;
                    }
                    for (const key of Object.keys(values)) {
                        if (!allowed.includes(key))
                            problems.push(item + " has no option " + key + " (it has " + allowed.join(", ") + ")");
                        else if (typeof values[key] !== "boolean")
                            problems.push("the option " + key + " of " + item + " must be true or false");
                    }
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
                version: 2,
                left: data.left ?? [],
                center: data.center ?? [],
                right: data.right ?? [],
                options: data.options ?? {}
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
        const line = list => JSON.stringify(list).replace(/,/g, ", ").replace(/":/g, "\": ");
        let text = "{\n  \"version\": 2,\n  \"left\": " + line(data.left) + ",\n  \"center\": " + line(data.center) + ",\n  \"right\": " + line(data.right);
        if (Object.keys(data.options ?? {}).length > 0)
            text += ",\n  \"options\": " + line(data.options);
        return text + "\n}\n";
    }

    // Writes a layout as the file: the whole of it, to a temporary file that then replaces it, so the
    // watcher (this one) never reads half of it. The folder is made if it is not there. Only a layout
    // that passes the check is written: the editor can never leave you with a file that is not used.
    function save(data: var): bool {
        const complete = { version: 2, left: data.left ?? [], center: data.center ?? [], right: data.right ?? [], options: data.options ?? {} };
        const problems = check(complete);
        if (problems.length > 0) {
            console.warn("sol-shell: not saving the bar layout: " + problems.join("; "));
            ShellMessages.error("Bar layout", "The layout could not be saved", problems.join("; ") + ".", "bar-layout-save");
            return false;
        }
        writer.command = ["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1.tmp\" && mv \"$1.tmp\" \"$1\"", "sh", path, format(complete)];
        writer.running = true;
        return true;
    }

    // The layout a style draws, as the data of a layout file (the starting point of "Customize", and of the
    // presets that are a style's own). Groups stay pills, and `hidden` says which items are left out. With
    // `compact`, the compact layout is used: the items its menu stands for go into the dropdown (where
    // the style puts its menu), and the clock and the media controls are compact.
    function fromStyle(style: var, compact: bool, hidden: var): var {
        const useCompact = compact && !!style.compactSections;
        const base = useCompact ? style.compactSections : style.sections;
        const name = entry => typeof entry === "string" ? entry : entry.atom;
        const result = { version: 2, left: [], center: [], right: [], options: {} };
        let menuMade = false;
        for (const side of ["left", "center", "right"]) {
            for (const entry of base[side] ?? []) {
                const kept = [];
                let menuHere = false;
                for (const inner of Array.isArray(entry) ? entry : [entry]) {
                    const atom = name(inner);
                    if (atom === BarStyle.compactMenuAtom)
                        menuHere = true;
                    else if (!hidden(atom))
                        kept.push(atom);
                }
                if (Array.isArray(entry)) {
                    if (kept.length > 0)
                        result[side].push(kept);
                } else {
                    kept.forEach(atom => result[side].push(atom));
                }
                // the dropdown goes next to the entry that held the menu, never inside a pill
                const inMenu = BarStyle.compactRemoved.filter(atom => !hidden(atom));
                if (menuHere && !menuMade && inMenu.length > 0) {
                    menuMade = true;
                    result[side].push({ menu: inMenu });
                }
            }
        }
        if (useCompact) {
            result.options = { clock: { compact: true }, media: { compact: true } };
        }
        return result;
    }

    // creates the file from the layout the style draws now: what is hidden now stays out of it, so
    // nothing appears or disappears when you press Customize
    function customize(): void {
        save(fromStyle(BarStyle.current, Settings.compactBar, BarStyle.chipHidden));
    }

    // Moves an item to a place in your layout (see utils/layoutMove.js for what a target is) and saves it.
    function move(name: string, target: var): void {
        if (!layout)
            return;
        const next = Move.moved(layout, name, target);
        if (next)
            save(next);
    }

    // Sets one option of one item of your layout (the clock's "compact", the workspaces' "monitorName") and
    // saves it. The value is true or false.
    function setOption(atom: string, key: string, value: bool): bool {
        if (!layout)
            return false;
        const next = JSON.parse(JSON.stringify(layout));
        next.options = next.options ?? {};
        next.options[atom] = Object.assign({}, next.options[atom] ?? {}, { [key]: value });
        return save(next);
    }

    // Takes an item out of your layout: it is then hidden, like any item the layout does not list. The
    // settings item cannot be hidden: it is the way back here.
    function unplace(name: string): void {
        if (!layout || name === BarStyle.requiredAtom)
            return;
        const next = Move.removed(layout, name);
        if (next)
            save(next);
    }

    // ---- presets and layouts you save ----

    // Ready-made arrangements (only the arrangement: no bar style or position). Two are the layouts the
    // styles come with, without the items that start hidden; the other is made here. An item a preset
    // does not list is hidden, so each of them lists every item it shows.
    readonly property var presets: [
        { id: "minimal", label: "Minimal style", layout: fromStyle(BarStyle.styles.minimal, false, atom => BarStyle.hiddenByDefault.includes(atom)) },
        { id: "islands", label: "Islands style", layout: fromStyle(BarStyle.styles.islands, false, atom => BarStyle.hiddenByDefault.includes(atom)) },
        {
            id: "dashboard",
            label: "Dashboard",
            layout: {
                version: 2,
                left: [["power", "launcher"], ["workspaces"]],
                center: [["clock", "weather"], "media"],
                right: [["cpu", "memory"], ["volume", "colorPicker", "wifi", "bluetooth"], ["nightLight", "keyboard"], ["tray"], ["updates", "vpn", "privacy", "battery", "powerMode", "bell", "settings"]],
                options: {}
            }
        }
    ]

    // Makes a preset the layout in use, by its id. (The editor's buttons only carry the id: a layout is
    // nested lists, and a list inside a list does not stay a list when a Repeater hands it to a delegate.)
    function applyPreset(id: string): bool {
        const preset = presets.find(p => p.id === id);
        if (!preset)
            return false;
        return save(preset.layout);
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

        // `option clock compact true`: an option of one item of the layout in use
        function option(atom: string, key: string, value: string): string {
            if (value !== "true" && value !== "false")
                return "the value must be true or false";
            if (!root.layout)
                return "no layout is in use: customize first";
            return root.setOption(atom, key, value === "true") ? "set " + atom + " " + key + " " + value : "not set (see the card)";
        }

        // `customize`: makes the layout file from the layout the style draws now (what the Customize button does)
        function customize(): string {
            root.customize();
            return "customizing";
        }

        // `list`: the presets and the layouts you saved, by name
        function list(): string {
            root.refreshSaved();
            return "presets: " + root.presets.map(p => p.id).join(", ") + "\nsaved: " + (root.saved.length > 0 ? root.saved.join(", ") : "none");
        }

        // `apply minimal` or `apply "my layout"`: a preset or a saved layout becomes the layout in use
        function apply(name: string): string {
            if (root.presets.some(p => p.id === name)) {
                root.applyPreset(name);
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
