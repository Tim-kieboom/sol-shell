import Quickshell
import QtQuick
import QtQuick.Layouts
import "../../../singletons"
import "../../../utils"

Row {

    // Just the ring: no icon, no number. Volume is the fill, mute is the color.
    StatusRing {
        // Inside a layout, size comes from implicitWidth/Height (plain width/height
        // would be overridden by the layout).
        implicitWidth: 18
        implicitHeight: 18

        visible: AudioService.available
        // min(1, ...) so going past 100% doesn't make the arc wrap around
        value: Math.min(1, AudioService.volume)
        ringWidth: 4
        ringColor: AudioService.muted ? Theme.mutedText : Theme.accent

        onClicked: AudioService.toggleMute()
        onScrolled: delta => AudioService.changeVolume(delta)
    }

    function getIcon(): string {
        return AudioService.muted ? Icons.volumeOff : Icons.volume;
    }
}
