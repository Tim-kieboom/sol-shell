.pragma library

// The moves of the layout editor, on the plain data of a layout file: { left, center, right }, each a
// list of item names and lists of names (pills). Nothing here knows about the screen, so it can be
// tried on its own. Every function returns a new layout and leaves its argument alone; a move that
// changes nothing (or cannot be done) returns null.
//
// An entry of a side is an item's name, a list (a pill) of names and at most one dropdown, or { menu: [names] }:
// the dropdown, on a side or inside a pill. A layout has at most one dropdown, and only the items in
// MENU_ATOMS (the ones that have a row in the menu) can go into it; a move that would break either rule
// returns null. There are three kinds of move: an item (`moved`), the dropdown with its items (`movedMenu`),
// and a pill with what is in it (`movedPill`).
//
// A target says where an item goes, by naming a neighbour rather than a position, because taking the
// item out of its old place shifts the positions:
//   { before: "clock" }        in the same place as "clock" (a side or a pill), just before it
//   { after: "clock" }         just after it
//   { end: "right" }           at the end of a side, outside any pill
//   { endOfPillWith: "cpu" }   at the end of the pill that "cpu" is in
//   { newPill: "left" }        in a new pill of its own, at the end of a side
//   { newMenu: "right" }       in a new dropdown, at the end of a side (when there is none yet)

var SIDES = ["left", "center", "right"];

// the items that can go in the dropdown: all of them but the menu itself (the three-dots item). The six that
// have a menu line of their own (volume, wifi, bluetooth, colorPicker, nightLight, keepAwake) show it; any other
// item is shown in the menu as itself (BarLayoutService checks that this list is every item of BarStyle).
var MENU_ATOMS = [
    "power", "workspaces", "media", "volume", "clock", "weather", "cpu", "memory", "colorPicker", "wifi", "bluetooth",
    "bell", "settings", "launcher", "keyboard", "nightLight", "privacy", "tray", "uptime", "disk", "networkSpeed",
    "updates", "battery", "powerMode", "vpn", "keepAwake"
];

function isMenu(entry) {
    return entry !== null && typeof entry === "object" && !Array.isArray(entry) && Array.isArray(entry.menu);
}

// the names of the items in an entry, the ones inside a pill or a dropdown too
function names(entry) {
    if (typeof entry === "string")
        return [entry];
    if (isMenu(entry))
        return entry.menu.slice();
    var out = [];
    (entry || []).forEach(function (e) { out = out.concat(names(e)); });
    return out;
}

// the list of entries inside an entry that holds some (a pill or the dropdown), or null for a plain name
function members(entry) {
    return Array.isArray(entry) ? entry : (isMenu(entry) ? entry.menu : null);
}

function hasMenu(data) {
    return SIDES.some(function (side) {
        return data[side].some(function (entry) {
            return isMenu(entry) || (Array.isArray(entry) && entry.some(isMenu));
        });
    });
}

function clone(data) {
    return JSON.parse(JSON.stringify(data));
}

function same(a, b) {
    return JSON.stringify(a) === JSON.stringify(b);
}

// an empty pill or dropdown is nothing: a list of entries with the empty ones taken out (a pill that was
// only a dropdown, now empty, goes too)
function tidy(list) {
    return list.map(function (entry) {
        if (Array.isArray(entry))
            return tidy(entry);
        return entry;
    }).filter(function (entry) {
        if (isMenu(entry))
            return entry.menu.length > 0;
        return Array.isArray(entry) ? entry.length > 0 : true;
    });
}

// the layout without the item `name`
function without(data, name) {
    var next = clone(data);
    SIDES.forEach(function (side) {
        function strip(list) {
            return list.map(function (entry) {
                if (Array.isArray(entry))
                    return strip(entry);
                if (isMenu(entry))
                    return { menu: entry.menu.filter(function (n) { return n !== name; }) };
                return entry;
            }).filter(function (entry) { return entry !== name; });
        }
        next[side] = tidy(strip(next[side]));
    });
    return next;
}

// where `name` is: { list, index, kind } with `list` the array that holds it and `kind` "side", "pill" or
// "menu" for what that array is; or null
function find(data, name) {
    for (var s = 0; s < SIDES.length; s++) {
        var side = data[SIDES[s]];
        for (var i = 0; i < side.length; i++) {
            var entry = side[i];
            if (entry === name)
                return { list: side, index: i, kind: "side", menu: false };
            if (isMenu(entry)) {
                var inMenu = entry.menu.indexOf(name);
                if (inMenu >= 0)
                    return { list: entry.menu, index: inMenu, kind: "menu", menu: true };
            } else if (Array.isArray(entry)) {
                for (var j = 0; j < entry.length; j++) {
                    if (entry[j] === name)
                        return { list: entry, index: j, kind: "pill", menu: false };
                    if (isMenu(entry[j])) {
                        var deep = entry[j].menu.indexOf(name);
                        if (deep >= 0)
                            return { list: entry[j].menu, index: deep, kind: "menu", menu: true };
                    }
                }
            }
        }
    }
    return null;
}

// the dropdown: { object, list, index, kind } where `list` holds it ("side" or "pill"), or null
function findMenu(data) {
    for (var s = 0; s < SIDES.length; s++) {
        var side = data[SIDES[s]];
        for (var i = 0; i < side.length; i++) {
            if (isMenu(side[i]))
                return { object: side[i], list: side, index: i, kind: "side" };
            if (Array.isArray(side[i])) {
                for (var j = 0; j < side[i].length; j++) {
                    if (isMenu(side[i][j]))
                        return { object: side[i][j], list: side[i], index: j, kind: "pill" };
                }
            }
        }
    }
    return null;
}

// the entry of a side that holds the item `name` (or the dropdown, for "@menu"): { list, index } or null
function entryOf(data, name) {
    for (var s = 0; s < SIDES.length; s++) {
        var side = data[SIDES[s]];
        for (var i = 0; i < side.length; i++) {
            var inside = name === "@menu" ? (isMenu(side[i]) || (Array.isArray(side[i]) && side[i].some(isMenu))) : names(side[i]).indexOf(name) >= 0;
            if (inside)
                return { list: side, index: i };
        }
    }
    return null;
}

// `name` moved to `target`, or null when nothing would change
function moved(data, name, target) {
    var neighbour = target.before !== undefined ? target.before : target.after !== undefined ? target.after : target.endOfPillWith;
    if (neighbour === name && target.endOfPillWith === undefined)
        return null;

    // for "end of the pill", an item of that pill that stays when `name` leaves it
    var survivor = null;
    if (target.endOfPillWith !== undefined) {
        var home = find(data, target.endOfPillWith);
        if (!home)
            return null;
        survivor = home.list.filter(function (n) { return typeof n === "string" && n !== name; })[0];
        if (survivor === undefined)
            return null;
    }

    var inMenu = MENU_ATOMS.indexOf(name) >= 0;
    var next = without(data, name);
    if (target.end !== undefined) {
        next[target.end].push(name);
    } else if (target.newPill !== undefined) {
        next[target.newPill].push([name]);
    } else if (target.newMenu !== undefined) {
        if (!inMenu || hasMenu(next))
            return null;
        next[target.newMenu].push({ menu: [name] });
    } else if (survivor !== null) {
        var pill = find(next, survivor);
        if (!pill || (pill.menu && !inMenu))
            return null;
        pill.list.push(name);
    } else {
        var place = find(next, neighbour);
        if (!place || (place.menu && !inMenu))
            return null;
        place.list.splice(place.index + (target.after !== undefined ? 1 : 0), 0, name);
    }
    return same(next, data) ? null : next;
}

// The dropdown, with its items, moved to `target`: the same targets as for an item (before or after an item,
// the end of a side, the end of a pill, a pill of its own), where the dropdown is the thing that moves. It
// can go inside a pill, never inside itself. Null when nothing would change.
function movedMenu(data, target) {
    var home = findMenu(data);
    if (!home)
        return null;
    var next = clone(data);
    var at = findMenu(next);
    var menu = at.object;
    at.list.splice(at.index, 1);
    SIDES.forEach(function (side) { next[side] = tidy(next[side]); });

    var neighbour = target.before !== undefined ? target.before : target.after !== undefined ? target.after : target.endOfPillWith;
    if (neighbour !== undefined && menu.menu.indexOf(neighbour) >= 0)
        return null;
    var side = target.end !== undefined ? target.end : target.newMenu;
    if (side !== undefined) {
        next[side].push(menu);
    } else if (target.newPill !== undefined) {
        next[target.newPill].push([menu]);
    } else if (target.endOfPillWith !== undefined) {
        var pill = find(next, target.endOfPillWith);
        if (!pill || pill.kind !== "pill")
            return null;
        pill.list.push(menu);
    } else {
        var place = find(next, neighbour);
        if (!place || place.kind === "menu")
            return null;
        place.list.splice(place.index + (target.after !== undefined ? 1 : 0), 0, menu);
    }
    return same(next, data) ? null : next;
}

// A pill, the one that holds the item `name`, moved with everything in it: before or after the entry of a side
// that holds another item (or the dropdown, "@menu"), or to the end of a side. Targets:
//   { beforeEntryOf: "clock" }   { afterEntryOf: "clock" }   { end: "right" }
// Null when `name` is not in a pill, when the target is in the pill itself, or when nothing would change.
function movedPill(data, name, target) {
    var next = clone(data);
    var at = find(next, name);
    if (!at || at.kind !== "pill")
        return null;
    var pill = at.list;
    var inside = names(pill);
    var neighbour = target.beforeEntryOf !== undefined ? target.beforeEntryOf : target.afterEntryOf;
    if (neighbour !== undefined && (inside.indexOf(neighbour) >= 0 || (neighbour === "@menu" && pill.some(isMenu))))
        return null;
    // take the pill out of its side
    for (var s = 0; s < SIDES.length; s++) {
        var i = next[SIDES[s]].indexOf(pill);
        if (i >= 0)
            next[SIDES[s]].splice(i, 1);
    }
    if (target.end !== undefined) {
        next[target.end].push(pill);
    } else {
        var place = entryOf(next, neighbour);
        if (!place)
            return null;
        place.list.splice(place.index + (target.afterEntryOf !== undefined ? 1 : 0), 0, pill);
    }
    return same(next, data) ? null : next;
}

// `name` taken out of the layout (it is then hidden), or null
function removed(data, name) {
    if (!find(data, name))
        return null;
    return without(data, name);
}
