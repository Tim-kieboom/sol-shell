// The tests of the layout editor's moves (utils/layoutMove.js), on plain data:
//
//     nix-shell -p nodejs --run "node tests/layoutMove.test.js utils/layoutMove.js"
//
// Prints "ok" or "FAIL" for each case, and exits with 1 if any failed.
const fs = require("fs");
const src = fs.readFileSync(process.argv[2], "utf8").replace(".pragma library", "") + "\nmodule.exports = { moved, removed, movedMenu, movedPill, names, MENU_ATOMS };";
const m = { exports: {} }; new Function("module", src)(m);
const { moved, removed, movedMenu, movedPill, names, MENU_ATOMS } = m.exports;
const L = () => ({ left: ["power", ["launcher", "workspaces"]], center: [["cpu", "memory"], "media"], right: [["clock", "weather"], "volume", "settings"] });
let failed = 0;
const eq = (name, got, want) => { const g = JSON.stringify(got), w = JSON.stringify(want); if (g !== w) { failed++; console.log("FAIL", name, "\n  got ", g, "\n  want", w); } else console.log("ok  ", name); };
eq("before in side", moved(L(), "volume", { before: "power" }).right, [["clock","weather"],"settings"]);
eq("before in side (left)", moved(L(), "volume", { before: "power" }).left, ["volume","power",["launcher","workspaces"]]);
eq("after in side", moved(L(), "power", { after: "volume" }).right, [["clock","weather"],"volume","power","settings"]);
eq("into a pill, before", moved(L(), "volume", { before: "memory" }).center, [["cpu","volume","memory"],"media"]);
eq("into a pill, after", moved(L(), "volume", { after: "weather" }).right, [["clock","weather","volume"],"settings"]);
eq("out of a pill", moved(L(), "workspaces", { end: "left" }).left, ["power",["launcher"],"workspaces"]);
eq("pill emptied is dropped", moved(L(), "media", { end: "left" }).center, [["cpu","memory"]]);
eq("single member pill dissolves", moved({left:[["a"]],center:[],right:[]}, "a", { end: "right" }), {left:[],center:[],right:["a"]});
eq("end of pill", moved(L(), "settings", { endOfPillWith: "clock" }).right, [["clock","weather","settings"],"volume"]);
eq("end of own pill (moves to the end)", moved(L(), "clock", { endOfPillWith: "weather" }).right, [["weather","clock"],"volume","settings"]);
eq("end of pill, only member", moved({left:[["a"]],center:[],right:[]}, "a", { endOfPillWith: "a" }), null);
eq("new pill", moved(L(), "volume", { newPill: "center" }).center, [["cpu","memory"],"media",["volume"]]);
eq("new pill from pill member", moved(L(), "cpu", { newPill: "left" }).center, [["memory"],"media"]);
eq("onto itself", moved(L(), "volume", { before: "volume" }), null);
eq("no change (before its next)", moved(L(), "volume", { before: "settings" }), null);
eq("no change (after its previous)", moved(L(), "settings", { after: "volume" }), null);
eq("unknown neighbour", moved(L(), "volume", { before: "nope" }), null);
eq("unplaced item in", moved(L(), "battery", { after: "power" }).left, ["power","battery",["launcher","workspaces"]]);
eq("unplaced item into a pill", moved(L(), "battery", { endOfPillWith: "cpu" }).center, [["cpu","memory","battery"],"media"]);
eq("remove", removed(L(), "volume").right, [["clock","weather"],"settings"]);
eq("remove from pill, pill stays", removed(L(), "launcher").left, ["power",["workspaces"]]);
eq("remove not placed", removed(L(), "battery"), null);
// the dropdown: { menu: [names] } holds only the items that have a menu row, and there is at most one
const M = () => ({ left: ["power", { menu: ["wifi", "bluetooth"] }], center: [["cpu", "memory"], "clock"], right: ["volume", "settings", "nightLight"] });
eq("into the dropdown, after", moved(M(), "volume", { after: "wifi" }).left, ["power", { menu: ["wifi", "volume", "bluetooth"] }]);
eq("into the dropdown, end of it", moved(M(), "nightLight", { endOfPillWith: "wifi" }).left, ["power", { menu: ["wifi", "bluetooth", "nightLight"] }]);
eq("any item goes into the dropdown, a clock too", moved(M(), "clock", { after: "wifi" }).left, ["power", { menu: ["wifi", "clock", "bluetooth"] }]);
eq("the menu itself does not go into the dropdown", moved(M(), "quickSettings", { after: "wifi" }), null);
eq("the cpu goes into the dropdown", moved(M(), "cpu", { endOfPillWith: "bluetooth" }).left, ["power", { menu: ["wifi", "bluetooth", "cpu"] }]);
eq("out of the dropdown", moved(M(), "wifi", { end: "right" }).left, ["power", { menu: ["bluetooth"] }]);
eq("out of the dropdown, to the side", moved(M(), "wifi", { end: "right" }).right, ["volume", "settings", "nightLight", "wifi"]);
eq("dropdown emptied is gone", moved({ left: [{ menu: ["wifi"] }], center: [], right: [] }, "wifi", { end: "right" }), { left: [], center: [], right: ["wifi"] });
eq("a new dropdown", moved({ left: ["power"], center: [], right: ["volume"] }, "volume", { newMenu: "right" }).right, [{ menu: ["volume"] }]);
eq("a second dropdown refused", moved(M(), "volume", { newMenu: "right" }), null);
eq("a new dropdown from a clock", moved({ left: [], center: [], right: ["clock"] }, "clock", { newMenu: "right" }).right, [{ menu: ["clock"] }]);
eq("a new dropdown refused for the menu item", moved({ left: [], center: [], right: ["quickSettings"] }, "quickSettings", { newMenu: "right" }), null);
eq("every item but the menu can go in the dropdown", MENU_ATOMS.length, 26);
eq("the menu item cannot", MENU_ATOMS.includes("quickSettings"), false);
eq("remove from the dropdown", removed(M(), "wifi").left, ["power", { menu: ["bluetooth"] }]);
// the dropdown can move, with its items, and sit inside a pill
const P = () => ({ left: ["power", { menu: ["wifi", "bluetooth"] }, ["launcher", "workspaces"]], center: [["cpu", "memory"], "clock"], right: ["volume", "settings"] });
eq("the dropdown into a pill", movedMenu(P(), { endOfPillWith: "cpu" }).center, [["cpu", "memory", { menu: ["wifi", "bluetooth"] }], "clock"]);
eq("the dropdown into a pill leaves its old place", movedMenu(P(), { endOfPillWith: "cpu" }).left, ["power", ["launcher", "workspaces"]]);
eq("the dropdown before an item of a pill", movedMenu(P(), { before: "workspaces" }).left, ["power", ["launcher", { menu: ["wifi", "bluetooth"] }, "workspaces"]]);
eq("the dropdown before a side item", movedMenu(P(), { before: "clock" }).center, [["cpu", "memory"], { menu: ["wifi", "bluetooth"] }, "clock"]);
eq("the dropdown to the end of a side", movedMenu(P(), { end: "right" }).right, ["volume", "settings", { menu: ["wifi", "bluetooth"] }]);
eq("the dropdown into a pill of its own", movedMenu(P(), { newPill: "right" }).right, ["volume", "settings", [{ menu: ["wifi", "bluetooth"] }]]);
eq("the dropdown onto its own item is refused", movedMenu(P(), { before: "wifi" }), null);
eq("the dropdown where it is changes nothing", movedMenu(P(), { after: "power" }), null);
eq("the dropdown before an item in the pill next to it goes into that pill", movedMenu(P(), { before: "launcher" }).left, ["power", [{ menu: ["wifi", "bluetooth"] }, "launcher", "workspaces"]]);
eq("no dropdown, no move", movedMenu({ left: ["power"], center: [], right: [] }, { end: "right" }), null);
const Q = () => ({ left: ["power", ["launcher", { menu: ["wifi", "bluetooth"] }]], center: [], right: ["volume", "settings"] });
eq("items into a dropdown that is in a pill", moved(Q(), "volume", { after: "wifi" }).left, ["power", ["launcher", { menu: ["wifi", "volume", "bluetooth"] }]]);
eq("a clock into a dropdown in a pill", moved({ left: [["power", { menu: ["wifi"] }]], center: ["clock"], right: [] }, "clock", { after: "wifi" }).left, [["power", { menu: ["wifi", "clock"] }]]);
eq("items out of a dropdown in a pill, pill stays", moved(Q(), "wifi", { end: "right" }).left, ["power", ["launcher", { menu: ["bluetooth"] }]]);
eq("a dropdown emptied inside a pill is gone", moved({ left: [["launcher", { menu: ["wifi"] }]], center: [], right: [] }, "wifi", { end: "right" }).left, [["launcher"]]);
eq("a pill that was only an emptied dropdown is gone", moved({ left: [[{ menu: ["wifi"] }]], center: [], right: [] }, "wifi", { end: "right" }).left, []);
eq("end of the pill with a dropdown", moved(Q(), "volume", { endOfPillWith: "launcher" }).left, ["power", ["launcher", { menu: ["wifi", "bluetooth"] }, "volume"]]);
eq("a second dropdown is refused with one in a pill", moved(Q(), "volume", { newMenu: "right" }), null);
// whole pills
eq("a pill before a side item, from another side", movedPill(P(), "cpu", { beforeEntryOf: "power" }).left, [["cpu", "memory"], "power", { menu: ["wifi", "bluetooth"] }, ["launcher", "workspaces"]]);
eq("a pill to another side, before an item", movedPill(P(), "launcher", { beforeEntryOf: "volume" }).right, [["launcher", "workspaces"], "volume", "settings"]);
eq("a pill leaves its side", movedPill(P(), "launcher", { beforeEntryOf: "volume" }).left, ["power", { menu: ["wifi", "bluetooth"] }]);
eq("a pill after another entry", movedPill(P(), "launcher", { afterEntryOf: "power" }).left, ["power", ["launcher", "workspaces"], { menu: ["wifi", "bluetooth"] }]);
eq("a pill to the end of a side", movedPill(P(), "cpu", { end: "left" }).left, ["power", { menu: ["wifi", "bluetooth"] }, ["launcher", "workspaces"], ["cpu", "memory"]]);
eq("a pill before a dropdown", movedPill(P(), "cpu", { beforeEntryOf: "@menu" }).left, ["power", ["cpu", "memory"], { menu: ["wifi", "bluetooth"] }, ["launcher", "workspaces"]]);
eq("a pill with the dropdown moves with it", movedPill({ left: [["a", { menu: ["wifi"] }]], center: [], right: ["volume"] }, "a", { end: "right" }).right, ["volume", ["a", { menu: ["wifi"] }]]);
eq("a pill onto its own item is refused", movedPill(P(), "cpu", { beforeEntryOf: "memory" }), null);
eq("a pill onto its own dropdown is refused", movedPill({ left: [["a", { menu: ["wifi"] }]], center: [], right: [] }, "a", { beforeEntryOf: "@menu" }), null);
eq("a lone item is not a pill", movedPill(P(), "power", { end: "right" }), null);
eq("an item of the dropdown is not a pill", movedPill(P(), "wifi", { end: "right" }), null);
eq("a pill where it is changes nothing", movedPill(P(), "launcher", { end: "left" }), null);
eq("names of an entry", names(["a", { menu: ["b", "c"] }]), ["a", "b", "c"]);
const p0 = P(); movedPill(p0, "cpu", { end: "left" }); movedMenu(p0, { end: "right" }); eq("moves leave their argument alone", p0, P());
const a = L(); moved(a, "volume", { before: "power" }); eq("argument untouched", a, L());
process.exit(failed ? 1 : 0);
