import QtQuick
import QtQuick.Layouts
import "./components"
import "./components/indicators"
import "../utils"
import "../singletons"

// Builds the bar from a style (see statusbar/styles/MinimalStyle.qml): the atoms of each
// section, in order, with the gaps the style asks for. The three sections are separated by
// two stretches, so the middle one stays in the middle of the free space. A group of atoms in
// a section is drawn as an island: a rounded panel around them (see IslandsStyle.qml).
Item {
    id: root

    // the monitor this bar is on (some atoms show it or need it)
    required property string screenName
    // the style to draw: BarStyle.current
    required property var style
    // the atoms to draw it with: the style's own, or its compact ones (see BarStyle)
    readonly property var sections: BarStyle.sectionsOf(style)

    // ---- the atoms ----
    //
    // The names a style can use. A Component is a recipe: the Loader below turns it into
    // a real item, once per entry. An atom that needs to know the monitor gets it here.
    readonly property var atoms: ({
            power: powerAtom,
            launcher: launcherAtom,
            workspaces: workspacesAtom,
            media: mediaAtom,
            volume: volumeAtom,
            clock: clockAtom,
            weather: weatherAtom,
            cpu: cpuAtom,
            memory: memoryAtom,
            colorPicker: colorPickerAtom,
            wifi: wifiAtom,
            bluetooth: bluetoothAtom,
            bell: bellAtom,
            settings: settingsAtom,
            quickSettings: quickSettingsAtom
        })

    Component {
        id: powerAtom
        PowerMenu {}
    }
    Component {
        id: launcherAtom
        Launcher {}
    }
    Component {
        id: workspacesAtom
        Workspace {
            screenName: root.screenName
        }
    }
    Component {
        id: mediaAtom
        Media {}
    }
    Component {
        id: volumeAtom
        VolumeIndicator {}
    }
    Component {
        id: clockAtom
        Clock {}
    }
    Component {
        id: weatherAtom
        Weather {}
    }
    Component {
        id: cpuAtom
        Cpu {}
    }
    Component {
        id: memoryAtom
        Memory {}
    }
    Component {
        id: colorPickerAtom
        ColorPicker {
            screenName: root.screenName
        }
    }
    Component {
        id: wifiAtom
        Wifi {}
    }
    Component {
        id: bluetoothAtom
        Bluetooth {}
    }
    Component {
        id: bellAtom
        NotificationBell {}
    }
    Component {
        id: settingsAtom
        SettingsButton {}
    }
    Component {
        id: quickSettingsAtom
        QuickSettings {
            screenName: root.screenName
        }
    }

    // BarStyle.atomNames is what a style may name; every one of them has to be built here
    Component.onCompleted: {
        for (const name of BarStyle.atomNames) {
            if (!atoms[name])
                console.warn("sol-shell: the bar cannot build the atom", name, "although styles may name it");
        }
    }

    // ---- what takes clicks ----
    //
    // On a see-through bar only the islands (and any atom that sits outside one) take clicks;
    // the gaps between them let clicks through to the windows below. Every one of those
    // items lists itself here, and Statusbar turns the list into the window's input mask.
    // `shown` says whether it is on screen: a hidden one must not keep eating clicks.
    property var maskItems: []

    function addMask(item: var): void {
        maskItems = [...maskItems, item];
    }

    function removeMask(item: var): void {
        maskItems = maskItems.filter(i => i !== item);
    }

    // ---- reading the style ----

    // One atom entry as the delegates want it: { atom, gap, height, width }. A bare name
    // takes the default gap; the first one of a row has none (what sits before it is a
    // stretch, or the edge of an island).
    function atomEntry(entry: var, index: int, spacing: real): var {
        const named = typeof entry === "string";
        return {
            group: false,
            atom: named ? entry : entry.atom,
            gap: index === 0 ? 0 : (named ? undefined : entry.gap) ?? spacing,
            height: named ? undefined : entry.height,
            width: named ? undefined : entry.width,
            // properties to set on the atom itself, like { compact: true }
            props: named ? undefined : entry.props
        };
    }

    // A section's items: atoms, or groups (a list inside the list) that become islands. What
    // the user has switched off is left out first, so the gaps close up: the first one left in a
    // row has no gap, and a group with nothing left is no island.
    function entries(list: var): var {
        const kept = [];
        for (const entry of list ?? []) {
            if (Array.isArray(entry)) {
                const inner = entry.filter(e => !BarStyle.isHidden(BarStyle.atomName(e)));
                if (inner.length > 0)
                    kept.push(inner);
            } else if (!BarStyle.isHidden(BarStyle.atomName(entry))) {
                kept.push(entry);
            }
        }
        return kept.map((entry, index) => {
            if (!Array.isArray(entry))
                return atomEntry(entry, index, root.style.itemSpacing);
            return {
                group: true,
                gap: index === 0 ? 0 : root.style.island.gap,
                atoms: entry.map((inner, innerIndex) => atomEntry(inner, innerIndex, root.style.island.itemSpacing))
            };
        });
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.style.edgeMargin
        anchors.rightMargin: root.style.edgeMargin
        // the gaps are the items' own (Layout.leftMargin below), not the layout's
        spacing: 0

        Repeater {
            model: root.entries(root.sections.left)
            delegate: slot
        }

        FillSpace {}

        Repeater {
            model: root.entries(root.sections.center)
            delegate: slot
        }

        FillSpace {}

        Repeater {
            model: root.entries(root.sections.right)
            delegate: slot
        }

        Spacer {
            size: root.sections.rightEnd ?? 0
        }
    }

    // ---- the items ----

    // One place in a row: an island, or an atom. This is the delegate of every Repeater here
    // (the sections, and the inside of an island).
    Component {
        id: slot

        Loader {
            id: place

            required property var modelData

            // `shown`: whether the item is on screen. An item cannot be asked whether it is
            // visible, because that depends on this Loader being visible; so every item
            // says it itself.
            readonly property bool shown: item ? item.shown : false

            Layout.leftMargin: modelData.gap
            Layout.preferredHeight: modelData.height ?? -1
            Layout.preferredWidth: modelData.width ?? -1
            sourceComponent: modelData.group ? island : atom
            visible: shown

            // `entry` is what the item is built from
            property var entry: modelData
        }
    }

    // an atom: the Loader inside builds the item the style named
    Component {
        id: atom

        Item {
            id: wrapper

            readonly property var entry: parent.entry
            // an atom that hides itself says so with `present`
            readonly property bool shown: inner.item ? (inner.item.present ?? true) : false
            // an atom outside any island on a see-through bar takes clicks itself
            readonly property bool bare: parent.parent?.isIslandRow !== true

            implicitWidth: inner.implicitWidth
            implicitHeight: inner.implicitHeight

            Loader {
                id: inner
                anchors.fill: parent
                sourceComponent: root.atoms[wrapper.entry.atom] ?? null

                // what the style asked of the atom (a property it does not have is an error
                // in the style, and is said so)
                onLoaded: {
                    const props = wrapper.entry.props ?? {};
                    for (const name in props) {
                        if (item[name] !== undefined)
                            item[name] = props[name];
                        else
                            console.warn("sol-shell: the atom", wrapper.entry.atom, "has no property", name);
                    }
                }
            }

            Component.onCompleted: {
                if (!root.atoms[entry.atom])
                    console.warn("sol-shell: the bar style names an atom that does not exist:", entry.atom);
                if (bare && !BarStyle.solidBar)
                    root.addMask(wrapper);
            }
            Component.onDestruction: root.removeMask(wrapper)
        }
    }

    // an island: a rounded panel with a row of atoms in it
    Component {
        id: island

        Rectangle {
            id: panel

            readonly property var entry: parent.entry
            // popups use this to hang from the island, not from the atom that opens them
            readonly property bool isIsland: true
            readonly property bool shown: row.anyShown

            // (`island` is missing for a moment when the style changes to one without islands:
            // the old islands are still there, about to be thrown away)
            implicitWidth: row.implicitWidth + 2 * (root.style.island?.padding ?? 0)
            implicitHeight: root.style.island?.height ?? 0
            radius: root.style.island?.radius ?? 0
            // the islands carry the fill on a see-through bar
            color: Theme.withOpacity(Theme.shellBackground, BarStyle.opacity)
            border.color: Theme.surfaceBorder
            border.width: 1

            RowLayout {
                id: row

                // for the atoms: they sit in an island
                readonly property bool isIslandRow: true
                // whether any atom in it is on screen: the island goes with the last one
                readonly property bool anyShown: {
                    for (const child of children) {
                        if (child.shown === true)
                            return true;
                    }
                    return false;
                }

                anchors.centerIn: parent
                spacing: 0

                Repeater {
                    model: panel.entry.atoms
                    delegate: slot
                }
            }

            Component.onCompleted: {
                if (!BarStyle.solidBar)
                    root.addMask(panel);
            }
            Component.onDestruction: root.removeMask(panel)
        }
    }
}
