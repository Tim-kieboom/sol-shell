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
            minimal: minimal
        })
    // the one that is used when nothing else can be, and must never be broken itself
    readonly property string fallbackName: "minimal"

    // The atoms (items of the bar) a style can list. BarRenderer builds one of each; it
    // says so in the log if it lacks one named here.
    readonly property var atomNames: ["power", "workspaces", "media", "volume", "clock", "weather", "cpu", "memory", "colorPicker", "wifi", "bluetooth", "bell", "settings"]
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

    // shortcuts for what the items need
    readonly property string position: current.position
    readonly property real barHeight: current.barHeight
    readonly property real popupGap: current.popupGap

    MinimalStyle {
        id: minimal
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

    // What is wrong with a style: one sentence per problem, none when it can be used.
    function check(style: var): var {
        const problems = [];
        const number = (value, least) => typeof value === "number" && isFinite(value) && value >= least;

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

        const sections = style.sections;
        if (!sections) {
            problems.push("there are no sections");
            return problems;
        }
        if (sections.rightEnd !== undefined && !number(sections.rightEnd, 0))
            problems.push("rightEnd is not a number of 0 or more");

        const seen = [];
        for (const part of ["left", "center", "right"]) {
            if (!Array.isArray(sections[part])) {
                problems.push("section " + part + " is not a list");
                continue;
            }
            for (const entry of sections[part]) {
                const named = typeof entry === "string";
                const atom = named ? entry : entry?.atom;
                if (typeof atom !== "string" || !atomNames.includes(atom)) {
                    problems.push("section " + part + " has an atom that does not exist: " + JSON.stringify(atom ?? entry));
                    continue;
                }
                seen.push(atom);
                if (!named && entry.gap !== undefined && !number(entry.gap, 0))
                    problems.push("the gap before " + atom + " is not a number of 0 or more");
            }
        }
        if (!seen.includes(requiredAtom))
            problems.push("it has no " + requiredAtom + " atom, so the settings could not be opened from the bar");
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
    IpcHandler {
        target: "barstyle"

        function current(): string {
            return root.resolved.name;
        }

        function problems(): string {
            return root.resolved.problems.join("\n");
        }
    }
}
