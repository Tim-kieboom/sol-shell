import Quickshell
import QtQuick
import "../../singletons"

// A popup that hangs off an item in the bar (the wifi popup, the power menu): below it, or
// above it when the style puts the bar at the bottom of the screen.
// It holds everything those popups have in common:
//
//   - the open/closed state, and clicking the icon again to close
//   - grabbing focus, so a click anywhere else closes it and typing works
//   - the see-through window with a rounded, bordered panel
//   - building the contents ONLY while the popup is open
//
// Usage: put exactly one item inside it; that item is the contents.
//
//     BarPopup {
//         id: popup
//         popupWidth: 280
//         ColumnLayout { ... }
//     }
//
// and call popup.toggle() when the icon is clicked.
Item {
    id: root

    // ---- settings ----

    // The item the popup hangs below. By default, whatever this sits inside.
    property Item anchorItem: root.parent
    // A popup at the right end of the bar must grow leftwards to stay on screen,
    // one at the left end grows rightwards.
    property bool alignRight: false
    property real popupWidth: 280
    // space between the panel's edge and the contents
    property real padding: 12

    // The contents. `default` means the item you put inside BarPopup lands here.
    // A Component is a recipe, not an item: it is only turned into a real item
    // (by the Loader below) when the popup opens, and thrown away when it closes.
    // That keeps closed popups free: no rows, no images, no bindings running.
    default property Component content

    // The island the item sits in, if it sits in one (see BarRenderer). The popup then hangs
    // from the island's edge, not the item's: the item is shorter than the island, and a
    // popup hung from it would cover the island's lower edge.
    readonly property Item island: {
        for (let item = root.parent; item; item = item.parent) {
            if (item.isIsland === true)
                return item;
        }
        return null;
    }

    // Which side of the item the popup hangs from: the one facing the middle of the screen.
    readonly property bool atBottom: BarStyle.position === "bottom"
    readonly property int facing: atBottom ? Edges.Top : Edges.Bottom

    // ---- state ----

    property bool open: false
    // when the popup last closed (ms since 1970), see toggle()
    property double closedAt: 0

    // How long after a close an open request is ignored. See toggle().
    readonly property int reopenGuardMs: 400

    // Called by the icon's click handler.
    function toggle(): void {
        if (open) {
            close();
        } else if (Date.now() - closedAt > reopenGuardMs) {
            // With the focus grab, a click outside the popup (the icon counts as
            // outside) already closes it. Without this check that same click would
            // reopen it right away, so an open request right after a close is ignored.
            open = true;
        }
    }

    function close(): void {
        open = false;
        closedAt = Date.now();
    }

    PopupWindow {
        // The popup is anchored to a rectangle of the bar window: the item's, or, for an item in
        // an island, as wide as the item (so the popup lines up with it) and as tall as the
        // island. (Anchoring to the item itself would not do for the island: the item is
        // shorter than the island, and the popup would cover the island's lower edge.)
        // `root.open` is read so the rectangle is worked out again each time the popup opens:
        // where things are is not something a binding can follow.
        anchor.window: root.QsWindow.window
        anchor.rect.x: (root.open, root.anchorItem.mapToItem(null, 0, 0).x)
        // The style's gap is made by growing the rectangle towards the middle of the screen:
        // the popup attaches to the rectangle's edge on that side.
        anchor.rect.y: (root.open, (root.island ?? root.anchorItem).mapToItem(null, 0, 0).y) - (root.atBottom ? BarStyle.popupGap : 0)
        anchor.rect.width: root.anchorItem.width
        anchor.rect.height: (root.island ?? root.anchorItem).height + BarStyle.popupGap
        // Attach to the item's corner on the side facing the screen, then grow away from
        // it. With the bar at the top that is the bottom corner and the popup grows down;
        // with the bar at the bottom it is the top corner and the popup grows up. The gap
        // is the style's.
        anchor.edges: root.facing | (root.alignRight ? Edges.Right : Edges.Left)
        anchor.gravity: root.facing | (root.alignRight ? Edges.Left : Edges.Right)

        visible: root.open
        // Grab the keyboard and let the compositor close the popup when you click
        // anywhere else. Must be set while hidden, which is why it is set here once.
        grabFocus: true
        // The compositor can close the popup by itself (click outside); mirror that
        // into our state so it doesn't go out of date.
        onVisibleChanged: {
            if (!visible && root.open)
                root.close();
        }

        implicitWidth: root.popupWidth
        // height follows the contents (0 until they are loaded)
        implicitHeight: (loader.item ? loader.item.implicitHeight : 0) + 2 * root.padding
        // the window itself is see-through; the Rectangle below draws the panel
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 12
            // half as see-through as the bar (the bar at 80% gives popups at 90%)
            color: Theme.withOpacity(Theme.shellBackground, BarStyle.popupOpacity)
            border.color: Theme.surfaceBorder
            border.width: 1

            Loader {
                id: loader
                anchors.fill: parent
                anchors.margins: root.padding
                // true = build the contents, false = destroy them
                active: root.open
                sourceComponent: root.content
            }
        }
    }
}
