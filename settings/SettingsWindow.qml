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
    // The window is as tall as the settings, but never taller than the screen (a little
    // space is left above and below): what does not fit scrolls.
    readonly property real screenMargin: 24

    implicitWidth: 340
    implicitHeight: Math.min(contentHeight + 2 * padding, screen.height - 2 * screenMargin)
    readonly property real contentHeight: loader.item ? loader.item.implicitHeight : 0

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

        // The settings can be taller than the window: they scroll (mouse wheel).
        Flickable {
            id: scroller
            anchors.fill: parent
            anchors.margins: root.padding
            contentWidth: width
            contentHeight: root.contentHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            focus: true
            Keys.onEscapePressed: SettingsService.close()

            // Built only while the window is open, so the wallpaper thumbnails are not decoded
            // every time something else happens.
            Loader {
                id: loader
                width: scroller.width
                height: root.contentHeight
                active: root.visible

                sourceComponent: SettingsPage {
                    onBack: SettingsService.close()
                }
            }
        }

        // a thin bar on the right edge while there is more to scroll to
        Rectangle {
            visible: scroller.contentHeight > scroller.height
            x: parent.width - width - 3
            y: root.padding + scroller.contentY * scroller.height / scroller.contentHeight
            width: 3
            height: scroller.height * scroller.height / scroller.contentHeight
            radius: 1.5
            color: Theme.surfaceBorder
        }
    }
}
