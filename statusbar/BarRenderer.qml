import QtQuick
import QtQuick.Layouts
import "./components"
import "./components/indicators"
import "../utils"
import "../singletons"

// Builds the bar from a style (see statusbar/styles/MinimalStyle.qml): the atoms of each
// section, in order, with the gaps the style asks for. The three sections are separated by
// two stretches, so the middle one stays in the middle of the free space.
Item {
    id: root

    // the monitor this bar is on (some atoms show it or need it)
    required property string screenName
    // the style to draw: BarStyle.current
    required property var style

    // ---- the atoms ----
    //
    // The names a style can use. A Component is a recipe: the Loader below turns it into
    // a real item, once per entry. An atom that needs to know the monitor gets it here.
    readonly property var atoms: ({
            power: powerAtom,
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
            settings: settingsAtom
        })

    Component {
        id: powerAtom
        PowerMenu {}
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

    // BarStyle.atomNames is what a style may name; every one of them has to be built here
    Component.onCompleted: {
        for (const name of BarStyle.atomNames) {
            if (!atoms[name])
                console.warn("sol-shell: the bar cannot build the atom", name, "although styles may name it");
        }
    }

    // A section's entries as the Repeaters want them: every entry as { atom, gap }. The
    // first one of a section has no gap: what sits before it is a stretch.
    function entries(list: var): var {
        return (list ?? []).map((entry, index) => {
            const named = typeof entry === "string";
            const gap = named ? undefined : entry.gap;
            return {
                atom: named ? entry : entry.atom,
                gap: index === 0 ? 0 : (gap ?? root.style.itemSpacing)
            };
        });
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.style.edgeMargin
        anchors.rightMargin: root.style.edgeMargin
        // the gaps are the atoms' own (Layout.leftMargin below), not the layout's
        spacing: 0

        Repeater {
            model: root.entries(root.style.sections.left)
            delegate: atomLoader
        }

        FillSpace {}

        Repeater {
            model: root.entries(root.style.sections.center)
            delegate: atomLoader
        }

        FillSpace {}

        Repeater {
            model: root.entries(root.style.sections.right)
            delegate: atomLoader
        }

        Spacer {
            size: root.style.sections.rightEnd ?? 0
        }
    }

    // One atom. An unknown name builds nothing (and says so in the log).
    Component {
        id: atomLoader

        Loader {
            id: loader

            required property var modelData

            Layout.leftMargin: modelData.gap
            sourceComponent: root.atoms[modelData.atom] ?? null
            // An atom that hides itself says so with `present` (an item cannot be asked
            // whether it is visible: that depends on this Loader being visible).
            visible: item ? (item.present ?? true) : false

            Component.onCompleted: {
                if (!root.atoms[modelData.atom])
                    console.warn("sol-shell: the bar style names an atom that does not exist:", modelData.atom);
            }
        }
    }
}
