import Quickshell
import QtQuick
import "../singletons"

// The status bar: one window along the top (or bottom) of a monitor. What is in it, and
// where, comes from the style (BarStyle.current); BarRenderer builds the rows from it.
// qmllint disable uncreatable-type
PanelWindow {
    id: root

    // the screen edge comes from the style; the window reserves its own height there
    anchors {
        top: BarStyle.position !== "bottom"
        bottom: BarStyle.position === "bottom"
        left: true
        right: true
    }
    implicitHeight: BarStyle.barHeight
    // A "solid" style is the strip: the window carries the fill. On a "transparent" one the
    // window has none and the islands carry it.
    color: BarStyle.solidBar ? Theme.withOpacity(Theme.shellBackground, BarStyle.opacity) : "transparent"

    // Only the islands take clicks on a see-through bar: the gaps between them (and the
    // strip of the screen above them) belong to the windows below. The renderer lists what
    // takes clicks; every item of that list becomes a region, and the mask is their union.
    // A strip has no mask (null): the whole window takes clicks.
    mask: BarStyle.solidBar ? null : islandMask

    Region {
        id: islandMask
        // every region is added to the others, not subtracted from them
        intersection: Intersection.Combine
        regions: maskRegions.list
    }

    Instantiator {
        id: maskRegions

        // the regions made so far, in the order of the renderer's list
        property var list: []

        model: renderer.maskItems
        // Each item is a plain rectangle that is worked out again whenever the item moves, grows
        // or hides, and not a region that follows the item by itself: that one has to be pointed at
        // the item, and pointed away again when it hides (so a hidden item does not keep eating
        // clicks at its old place), and a click mask that is out of step with what is on screen
        // is a part of the bar that stops taking clicks.
        delegate: Region {
            id: area

            required property var modelData

            // where the item is in the window; an item that is not shown has no area
            readonly property rect box: {
                if (!modelData.shown)
                    return Qt.rect(0, 0, 0, 0);
                // read these so the box is worked out again when any of them changes
                const width = modelData.width, height = modelData.height;
                modelData.x;
                modelData.y;
                renderer.width;
                renderer.height;
                const spot = modelData.mapToItem(renderer, 0, 0);
                return Qt.rect(Math.round(spot.x), Math.round(spot.y), Math.ceil(width), Math.ceil(height));
            }

            x: box.x
            y: box.y
            width: box.width
            height: box.height
        }
        onObjectAdded: collect()
        onObjectRemoved: collect()

        function collect(): void {
            const regions = [];
            for (let i = 0; i < count; i++)
                regions.push(objectAt(i));
            list = regions;
        }
    }

    BarRenderer {
        id: renderer
        anchors.fill: parent
        screenName: root.screen.name
        style: BarStyle.current
    }
}
