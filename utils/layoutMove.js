.pragma library

// The moves of the layout editor, on the plain data of a layout file: { left, center, right }, each a
// list of item names and lists of names (pills). Nothing here knows about the screen, so it can be
// tried on its own. Every function returns a new layout and leaves its argument alone; a move that
// changes nothing (or cannot be done) returns null.
//
// An entry of a side is an item's name, a list of names (a pill), or { menu: [names] }: the dropdown. A
// layout has at most one dropdown, and only the items in MENU_ATOMS (the ones that have a row in the
// menu) can go into it; a move that would break either rule returns null.
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

// the items that have a row in the dropdown (BarLayoutService and QuickSettings.qml use the same list)
var MENU_ATOMS = ["volume", "wifi", "bluetooth", "colorPicker", "nightLight", "keepAwake"];

function isMenu(entry) {
    return entry !== null && typeof entry === "object" && !Array.isArray(entry) && Array.isArray(entry.menu);
}

// the list of names inside an entry that holds some (a pill or the dropdown), or null for a plain name
function members(entry) {
    return Array.isArray(entry) ? entry : (isMenu(entry) ? entry.menu : null);
}

function hasMenu(data) {
    return SIDES.some(function (side) { return data[side].some(isMenu); });
}

function clone(data) {
    return JSON.parse(JSON.stringify(data));
}

// the layout without `name`: a pill or a dropdown that was left empty is gone too
function without(data, name) {
    var next = clone(data);
    SIDES.forEach(function (side) {
        next[side] = next[side].map(function (entry) {
            if (Array.isArray(entry))
                return entry.filter(function (n) { return n !== name; });
            if (isMenu(entry))
                return { menu: entry.menu.filter(function (n) { return n !== name; }) };
            return entry;
        }).filter(function (entry) {
            var inside = members(entry);
            return inside !== null ? inside.length > 0 : entry !== name;
        });
    });
    return next;
}

// the list that holds `name` (a side, a pill or the dropdown) and its place in it:
// { list, index, menu } (menu is true for the dropdown) or null
function find(data, name) {
    for (var s = 0; s < SIDES.length; s++) {
        var side = data[SIDES[s]];
        for (var i = 0; i < side.length; i++) {
            var entry = side[i];
            if (entry === name)
                return { list: side, index: i, menu: false };
            var inside = members(entry);
            if (inside !== null) {
                var at = inside.indexOf(name);
                if (at >= 0)
                    return { list: inside, index: at, menu: isMenu(entry) };
            }
        }
    }
    return null;
}

function same(a, b) {
    return JSON.stringify(a) === JSON.stringify(b);
}

// `name` moved to `target`, or null when nothing would change
function moved(data, name, target) {
    var neighbour = target.before !== undefined ? target.before : target.after !== undefined ? target.after : target.endOfPillWith;
    if (neighbour === name && target.endOfPillWith === undefined)
        return null;

    // for "end of the pill", a member of that pill that stays when `name` leaves it
    var survivor = null;
    if (target.endOfPillWith !== undefined) {
        var home = find(data, target.endOfPillWith);
        if (!home)
            return null;
        survivor = home.list.filter(function (n) { return n !== name; })[0];
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

// `name` taken out of the layout (the style then puts it at its default place), or null
function removed(data, name) {
    if (!find(data, name))
        return null;
    return without(data, name);
}
