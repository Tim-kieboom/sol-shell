import Quickshell
import Quickshell.Wayland
import QtQuick
import "../singletons"

// The idle inhibitor behind KeepAwakeService. Wayland ties an inhibitor to a window that is on
// screen, so this is a window of one transparent pixel that lets every click through.
PanelWindow {
    id: root

    implicitWidth: 1
    implicitHeight: 1
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "sol-keep-awake"
    mask: Region {}

    IdleInhibitor {
        enabled: KeepAwakeService.enabled
        window: root
    }
}
