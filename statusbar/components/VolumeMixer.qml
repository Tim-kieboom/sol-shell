import Quickshell
import QtQuick
import QtQuick.Layouts
import "../../singletons"

// The contents of the volume popup: the output volume, the list of output
// devices to switch between, and the microphone volume.
ColumnLayout {
    spacing: 12

    // ---------- output ----------
    VolumeControl {
        Layout.fillWidth: true
        icon: Icons.volume
        mutedIcon: Icons.volumeOff
        title: "Output"
        deviceName: AudioService.displayName(AudioService.sink)
        volume: AudioService.volume
        muted: AudioService.muted
        onVolumeRequested: value => AudioService.setVolume(value)
        onMuteToggled: AudioService.toggleMute()
    }

    // The devices. Click one to make it the default; the current one is marked.
    Column {
        Layout.fillWidth: true
        spacing: 2

        Repeater {
            // ScriptModel only adds and removes rows when a device appears or
            // disappears (a Bluetooth headset connecting), instead of rebuilding all
            model: ScriptModel {
                values: AudioService.sinks
            }

            ListRow {
                id: row
                required property var modelData
                readonly property bool isDefault: AudioService.isDefaultSink(modelData)

                width: parent.width
                icon: AudioService.iconFor(modelData)
                iconColor: isDefault ? Theme.accent : Theme.secondaryText
                title: AudioService.displayName(modelData)
                highlighted: isDefault

                onClicked: AudioService.setDefaultSink(modelData)

                // a check mark on the current device (goes into the row's right side)
                Text {
                    visible: row.isDefault
                    text: Icons.confirm
                    color: Theme.accent
                    font.family: Fonts.materialIconFontFamily
                    font.pixelSize: Fonts.bodyLarge
                }
            }
        }
    }

    // thin line between output and input
    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Theme.surfaceBorder
        visible: AudioService.micAvailable
    }

    // ---------- microphone ----------
    VolumeControl {
        Layout.fillWidth: true
        visible: AudioService.micAvailable
        icon: Icons.microphone
        title: "Microphone"
        deviceName: AudioService.displayName(AudioService.source)
        volume: AudioService.micVolume
        muted: AudioService.micMuted
        onVolumeRequested: value => AudioService.setMicVolume(value)
        onMuteToggled: AudioService.toggleMicMute()
    }
}
