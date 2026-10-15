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
        delegate: Region {
            required property var modelData
            // a hidden item keeps its old place; it must not keep taking clicks there
            item: modelData.shown ? modelData : null
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
