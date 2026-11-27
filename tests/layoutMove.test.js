// The tests of the layout editor's moves (utils/layoutMove.js), on plain data:
//
//     nix-shell -p nodejs --run "node tests/layoutMove.test.js utils/layoutMove.js"
//
// Prints "ok" or "FAIL" for each case, and exits with 1 if any failed.
const fs = require("fs");
const src = fs.readFileSync(process.argv[2], "utf8").replace(".pragma library", "") + "\nmodule.exports = { moved, removed, MENU_ATOMS };";
const m = { exports: {} }; new Function("module", src)(m);
const { moved, removed, MENU_ATOMS } = m.exports;
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
eq("into the dropdown refused for a clock", moved(M(), "clock", { after: "wifi" }), null);
eq("into the dropdown refused for the cpu", moved(M(), "cpu", { endOfPillWith: "bluetooth" }), null);
eq("out of the dropdown", moved(M(), "wifi", { end: "right" }).left, ["power", { menu: ["bluetooth"] }]);
eq("out of the dropdown, to the side", moved(M(), "wifi", { end: "right" }).right, ["volume", "settings", "nightLight", "wifi"]);
eq("dropdown emptied is gone", moved({ left: [{ menu: ["wifi"] }], center: [], right: [] }, "wifi", { end: "right" }), { left: [], center: [], right: ["wifi"] });
eq("a new dropdown", moved({ left: ["power"], center: [], right: ["volume"] }, "volume", { newMenu: "right" }).right, [{ menu: ["volume"] }]);
eq("a second dropdown refused", moved(M(), "volume", { newMenu: "right" }), null);
eq("a new dropdown refused for the clock", moved({ left: [], center: [], right: ["clock"] }, "clock", { newMenu: "right" }), null);
eq("menu items are the six", MENU_ATOMS, ["volume", "wifi", "bluetooth", "colorPicker", "nightLight", "keepAwake"]);
eq("remove from the dropdown", removed(M(), "wifi").left, ["power", { menu: ["bluetooth"] }]);
const a = L(); moved(a, "volume", { before: "power" }); eq("argument untouched", a, L());
process.exit(failed ? 1 : 0);
