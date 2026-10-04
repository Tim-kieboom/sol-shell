import QtQuick
import QtQuick.Layouts
import "../../singletons"
import "../../utils"

// One volume control: an icon that mutes, a title with the device it controls,
// the volume as a percentage, and a slider. Used for the output and for the
// microphone; it holds no state, the owner passes the values in and handles the
// two signals.
ColumnLayout {
    id: root

    property string icon
    // shown instead of `icon` while muted (defaults to the same icon, dimmed)
    property string mutedIcon: icon
    property string title
    property string deviceName
    property real volume: 0
    property bool muted: false

    signal volumeRequested(real value)   // the user moved the slider (0 to 1)
    signal muteToggled                   // the user clicked the icon

    spacing: 6

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        // Clicking the icon mutes. It is dimmed while muted, but must stay
        // clickable to unmute, so it is dimmed by opacity and not by `enabled`.
        IconButton {
            text: root.muted ? root.mutedIcon : root.icon
            opacity: root.muted ? 0.45 : 1.0
            onClicked: root.muteToggled()
        }

        Column {
            Layout.fillWidth: true

            Text {
                width: parent.width
                text: root.title
                color: Theme.primaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.bodySmall
            }

            Text {
                width: parent.width
                text: root.deviceName
                color: Theme.secondaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelSmall
                elide: Text.ElideRight
            }
        }

        Text {
            text: Math.round(root.volume * 100) + "%"
            color: root.muted ? Theme.mutedText : Theme.primaryText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.bodySmall
        }
    }

    VolumeSlider {
        Layout.fillWidth: true
        value: root.volume
        // dimmed while muted, like the icon
        opacity: root.muted ? 0.45 : 1.0
        onMoved: v => root.volumeRequested(v)
    }
}
