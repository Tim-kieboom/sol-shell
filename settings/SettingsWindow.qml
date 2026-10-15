import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../singletons"

// The settings, in a window of their own in the middle of the screen you are looking at.
// It is not part of the bar, so changing the bar's style (which rebuilds the bar) does not
// pull it away. Opened by SettingsService; a click anywhere else, Escape and the page's back
// button close it. With nothing open the window is hidden.
// qmllint disable uncreatable-type
PanelWindow {
    id: root

    // the monitor Hyprland says has the focus (the first one until it knows)
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    // no anchors: the compositor centers it
    // above normal windows and the bar, reserving no space
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "sol-settings"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // the panel draws its own background
    color: "transparent"
    visible: SettingsService.open

    readonly property real padding: 8

    implicitWidth: 340
    implicitHeight: (loader.item ? loader.item.implicitHeight : 0) + 2 * padding

    // a click outside the window closes it
    HyprlandFocusGrab {
        windows: [root]
        active: root.visible
        onCleared: SettingsService.close()
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        // the same look as the popups that hang off the bar
        color: Theme.withOpacity(Theme.shellBackground, BarStyle.popupOpacity)
        border.color: Theme.surfaceBorder
        border.width: 1

        // Built only while the window is open, so the wallpaper thumbnails are not decoded
        // every time something else happens.
        Loader {
            id: loader
            anchors.fill: parent
            anchors.margins: root.padding
            active: root.visible
            focus: true
            Keys.onEscapePressed: SettingsService.close()

            sourceComponent: SettingsPage {
                onBack: SettingsService.close()
            }
        }
    }
}
