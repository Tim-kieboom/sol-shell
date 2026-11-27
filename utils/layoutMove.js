.pragma library

// The moves of the layout editor, on the plain data of a layout file: { left, center, right }, each a
// list of item names and lists of names (pills). Nothing here knows about the screen, so it can be
// tried on its own. Every function returns a new layout and leaves its argument alone; a move that
// changes nothing (or cannot be done) returns null.
//
// A target says where an item goes, by naming a neighbour rather than a position, because taking the
// item out of its old place shifts the positions:
//   { before: "clock" }        in the same place as "clock" (a side or a pill), just before it
//   { after: "clock" }         just after it
//   { end: "right" }           at the end of a side, outside any pill
//   { endOfPillWith: "cpu" }   at the end of the pill that "cpu" is in
//   { newPill: "left" }        in a new pill of its own, at the end of a side

var SIDES = ["left", "center", "right"];

function clone(data) {
    return JSON.parse(JSON.stringify(data));
}

// the layout without `name`: a pill that was left empty is gone too
function without(data, name) {
    var next = clone(data);
    SIDES.forEach(function (side) {
        next[side] = next[side].map(function (entry) {
            return Array.isArray(entry) ? entry.filter(function (n) { return n !== name; }) : entry;
        }).filter(function (entry) {
            return Array.isArray(entry) ? entry.length > 0 : entry !== name;
        });
    });
    return next;
}

// the list that holds `name` (a side, or a pill) and its place in it: { list, index } or null
function find(data, name) {
    for (var s = 0; s < SIDES.length; s++) {
        var side = data[SIDES[s]];
        for (var i = 0; i < side.length; i++) {
            var entry = side[i];
            if (entry === name)
                return { list: side, index: i };
            if (Array.isArray(entry)) {
                var at = entry.indexOf(name);
                if (at >= 0)
                    return { list: entry, index: at };
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

    var next = without(data, name);
    if (target.end !== undefined) {
        next[target.end].push(name);
    } else if (target.newPill !== undefined) {
        next[target.newPill].push([name]);
    } else if (survivor !== null) {
        var pill = find(next, survivor);
        if (!pill)
            return null;
        pill.list.push(name);
    } else {
        var place = find(next, neighbour);
        if (!place)
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
