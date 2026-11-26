import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "../singletons"

// The popup for the volume keys: an icon, a bar and the percentage, low in the middle of the
// monitor you are looking at. It is one window that follows your focus, like the notification
// popups, and is hidden while OsdService.shown is false. Clicks go straight through it.
PanelWindow {
    id: root

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    // no anchors but the bottom: centered, a little above the edge
    anchors.bottom: true
    margins.bottom: 80

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "sol-osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    color: "transparent"
    visible: OsdService.shown

    // an empty input region: the pointer and clicks pass through to what is below
    mask: Region {}

    implicitWidth: 280
    implicitHeight: 52

    readonly property bool muted: AudioService.muted
    // a muted output shows an empty bar, whatever the volume under it is
    readonly property real fraction: muted ? 0 : AudioService.volume / AudioService.maxVolume

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.withOpacity(Theme.shellBackground, BarStyle.popupOpacity)
        border.color: Theme.surfaceBorder
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 12

            Text {
                text: root.muted || AudioService.volume === 0 ? Icons.volumeOff : Icons.volume
                color: root.muted ? Theme.mutedText : Theme.primaryText
                font.family: Fonts.materialIconFontFamily
                font.pixelSize: Fonts.titleSmall
            }

            // the bar runs to 150%; the tick marks 100%
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 6

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Theme.surface
                }

                Rectangle {
                    width: parent.width * root.fraction
                    height: parent.height
                    radius: height / 2
                    color: root.muted ? Theme.mutedText : AudioService.volume > 1 ? Theme.danger : Theme.accent
                }

                Rectangle {
                    x: parent.width / AudioService.maxVolume - width / 2
                    width: 2
                    height: parent.height + 4
                    y: -2
                    color: Theme.surfaceBorder
                }
            }

            Text {
                // a fixed width, so the bar does not change length between "9%" and "100%"
                Layout.preferredWidth: 40
                horizontalAlignment: Text.AlignRight
                text: root.muted ? "mute" : Math.round(AudioService.volume * 100) + "%"
                color: Theme.secondaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelMedium
            }
        }
    }
}
