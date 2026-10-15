pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../statusbar/styles"

// The style the bar is drawn in right now (see statusbar/styles/MinimalStyle.qml for what a
// style holds). Everything in the bar that depends on the style reads it from here, so
// switching styles changes the bar without touching the items.
//
// Which style is used is Settings.barStyle, checked before it is used: a style that does not
// exist, or that is broken (names an atom that does not exist, has no settings button, puts
// the bar nowhere), is not drawn. The minimalist style is drawn instead and the reason is
// logged and shown in the settings. That holds at startup and whenever the setting changes.
// The setting itself is never changed: fix the style and the bar follows.
Singleton {
    id: root

    // ---- the styles ----

    // the styles that ship, by the name Settings.barStyle uses
    readonly property var styles: ({
            minimal: minimal,
            islands: islands
        })
    // the same, in the order the settings list them
    readonly property var styleList: ["minimal", "islands"].map(id => ({
                id: id,
                label: styles[id].label
            }))
    // the one that is used when nothing else can be, and must never be broken itself
    readonly property string fallbackName: "minimal"

    // The atoms (items of the bar) a style can list. BarRenderer builds one of each; it
    // says so in the log if it lacks one named here.
    readonly property var atomNames: ["power", "workspaces", "media", "volume", "clock", "weather", "cpu", "memory", "colorPicker", "wifi", "bluetooth", "bell", "settings", "quickSettings"]
    // the one every style has to include: it is how you get to the settings
    readonly property string requiredAtom: "settings"

    // ---- what is used ----

    // what the user asked for
    readonly property string requested: Settings.barStyle
    // { name, style, problems }: the style that is used, and why not the requested one
    readonly property var resolved: resolve(requested)

    // the style object itself: BarRenderer reads the sections and spacing from it
    readonly property var current: resolved.style
    // empty when the requested style is in use; otherwise one line saying why it is not
    readonly property string fallbackReason: reasonFor(requested, resolved)

    // The atoms to draw a style with: its own, or its compact ones when the compact bar is on
    // (a style without a compact layout is drawn as it is). A function of the style, so the
    // renderer always reads the layout of the very style it is drawing.
    function sectionsOf(style: var): var {
        return Settings.compactBar && style.compactSections ? style.compactSections : style.sections;
    }

    // shortcuts for what the items need
    readonly property string position: current.position
    readonly property real barHeight: current.barHeight
    readonly property real popupGap: current.popupGap
    // whether the bar window is the strip (it carries the fill), or only holds the islands
    readonly property bool solidBar: current.surface === "solid"

    // ---- how see-through ----
    // The user's choice for the style in use (Settings keeps one per style), kept within the
    // style's range. A style the user has not touched starts at its own default.
    readonly property real minOpacity: current.opacity.min
    readonly property real opacity: {
        const saved = Settings.savedOpacity(resolved.name);
        const wanted = typeof saved === "number" ? saved : current.opacity.default;
        return Math.max(current.opacity.min, Math.min(1, wanted));
    }
    // popups are half as see-through as the bar (a bar at 80% gives popups at 90%)
    readonly property real popupOpacity: (1 + opacity) / 2
    function setOpacity(value: real): void {
        Settings.setSavedOpacity(resolved.name, value);
    }

    MinimalStyle {
        id: minimal
    }

    IslandsStyle {
        id: islands
    }

    function reasonFor(name: string, result: var): string {
        if (result.problems.length === 0)
            return "";
        return "The bar style \"" + name + "\" cannot be used (" + result.problems.join("; ") + "), so the " + fallbackName + " style is shown.";
    }

    function resolve(name: string): var {
        const wanted = styles[name];
        const problems = wanted ? check(wanted) : ["there is no such style"];
        if (problems.length === 0)
            return {
                name: name,
                style: wanted,
                problems: []
            };
        return {
            name: fallbackName,
            style: styles[fallbackName],
            problems: problems
        };
    }

    // What is wrong with one layout (`where` is "" or "compact ", for the messages): problems are
    // added to `problems`. Returns whether the layout has groups.
    function checkSections(sections: var, where: string, problems: var): bool {
        const number = (value, least) => typeof value === "number" && isFinite(value) && value >= least;
        let grouped = false;
        if (!sections) {
            problems.push("there are no " + where + "sections");
            return false;
        }
        if (sections.rightEnd !== undefined && !number(sections.rightEnd, 0))
            problems.push(where + "rightEnd is not a number of 0 or more");

        const seen = [];
        // one atom entry: its name, and the optional gap, height, width and props
        const checkAtom = (entry, part) => {
            const named = typeof entry === "string";
            const atom = named ? entry : entry?.atom;
            if (typeof atom !== "string" || !atomNames.includes(atom)) {
                problems.push(where + "section " + part + " has an atom that does not exist: " + JSON.stringify(atom ?? entry));
                return;
            }
            seen.push(atom);
            if (named)
                return;
            for (const key of ["gap", "height", "width"]) {
                if (entry[key] !== undefined && !number(entry[key], 0))
                    problems.push("the " + key + " of " + atom + " is not a number of 0 or more");
            }
            if (entry.props !== undefined && (typeof entry.props !== "object" || entry.props === null || Array.isArray(entry.props)))
                problems.push("the props of " + atom + " are not { name: value }");
        };
        for (const part of ["left", "center", "right"]) {
            if (!Array.isArray(sections[part])) {
                problems.push(where + "section " + part + " is not a list");
                continue;
            }
            for (const entry of sections[part]) {
                if (Array.isArray(entry)) {
                    grouped = true;
                    if (entry.length === 0)
                        problems.push(where + "section " + part + " has an empty group");
                    entry.forEach(inner => checkAtom(inner, part));
                } else {
                    checkAtom(entry, part);
                }
            }
        }
        if (!seen.includes(requiredAtom))
            problems.push("the " + where + "layout has no " + requiredAtom + " atom, so the settings could not be opened from the bar");
        return grouped;
    }

    // What is wrong with a style: one sentence per problem, none when it can be used.
    function check(style: var): var {
        const problems = [];
        const number = (value, least) => typeof value === "number" && isFinite(value) && value >= least;

        if (style.surface !== "solid" && style.surface !== "transparent")
            problems.push("surface is \"" + style.surface + "\", not solid or transparent");
        if (typeof style.label !== "string" || style.label === "")
            problems.push("it has no label");
        if (style.position !== "top" && style.position !== "bottom")
            problems.push("position is \"" + style.position + "\", not top or bottom");
        if (!number(style.barHeight, 1))
            problems.push("barHeight is not a number above 0");
        for (const key of ["edgeMargin", "popupGap", "itemSpacing"]) {
            if (!number(style[key], 0))
                problems.push(key + " is not a number of 0 or more");
        }

        const opacity = style.opacity;
        if (!opacity || !number(opacity.default, 0) || !number(opacity.min, 0) || opacity.default > 1 || opacity.min > 1)
            problems.push("opacity needs a default and a min between 0 and 1");
        else if (opacity.min > opacity.default)
            problems.push("the lowest opacity (" + opacity.min + ") is above the default (" + opacity.default + ")");

        // the layout, and the compact layout when the style has one: both are drawn, so both
        // have to be usable (and both have to have the settings atom)
        let grouped = false;
        grouped = checkSections(style.sections, "", problems) || grouped;
        if (style.compactSections !== undefined)
            grouped = checkSections(style.compactSections, "compact ", problems) || grouped;

        // groups are drawn as islands, which the style then has to describe
        if (grouped) {
            const island = style.island;
            if (!island || !number(island.height, 1) || !number(island.radius, 0) || !number(island.padding, 0) || !number(island.gap, 0) || !number(island.itemSpacing, 0))
                problems.push("it has groups, so it needs an island with a height, radius, padding, gap and itemSpacing");
        }
        return problems;
    }

    // ---- telling someone ----

    // (built from `resolved`, not from fallbackReason: that binding may not have updated yet)
    function report(): void {
        if (resolved.problems.length > 0)
            console.warn("sol-shell: " + reasonFor(requested, resolved));
    }

    onResolvedChanged: report()

    Component.onCompleted: {
        report();
        // The fallback is what you are left with when everything else fails: if it is itself
        // broken there is nothing to fall back to, so say so loudly.
        const own = check(styles[fallbackName]);
        if (own.length > 0)
            console.error("sol-shell: the built-in " + fallbackName + " bar style is broken: " + own.join("; "));
    }

    // For checking from a terminal (and from tests):
    //   sol-shell ipc call barstyle current     the style that is drawn
    //   sol-shell ipc call barstyle problems    why not the requested one (empty if it is)
    //   sol-shell ipc call barstyle opacity     the opacity in use, and its lowest value
    IpcHandler {
        target: "barstyle"

        function current(): string {
            return root.resolved.name;
        }

        function problems(): string {
            return root.resolved.problems.join("\n");
        }

        // how see-through the bar in use is (1 = solid), and the lowest it may be
        function opacity(): string {
            return root.opacity + " (lowest " + root.minOpacity + ")";
        }
    }
}
