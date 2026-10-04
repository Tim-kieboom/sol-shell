import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../singletons"

// The notification popups: a stack of cards in the top-right corner, newest on
// top, drawn above everything else. It is one window that follows your focus: the
// popups appear on the monitor you are looking at. With no notifications the
// window is hidden.
PanelWindow {
    id: root

    // the monitor Hyprland says has the focus (the first one until it knows)
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    anchors {
        top: true
        right: true
    }
    // a little space from the corner; the bar's own space is respected below
    margins {
        top: 8
        right: 12
    }

    // "Normal" with a zone of 0: sit next to other panels (so we land under the
    // status bar, not on top of it) without reserving any space ourselves.
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0

    // above normal windows and the bar
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "sol-notifications"

    // the cards draw their own background
    color: "transparent"
    visible: NotificationService.newestFirst.length > 0

    implicitWidth: 380
    implicitHeight: stack.implicitHeight

    Column {
        id: stack
        width: parent.width
        spacing: 8

        Repeater {
            // ScriptModel keeps the card of a notification that is still there
            // when a new one arrives, instead of rebuilding the whole stack
            model: ScriptModel {
                values: NotificationService.newestFirst
            }

            NotificationCard {
                required property var modelData
                notification: modelData
                width: stack.width
            }
        }
    }
}
