import QtQuick
import "../../../singletons"
import "../../../utils"
import "../"

// Volume as a bare ring: no icon, no number. The fill is the volume level and
// the color shows mute. Scroll changes the volume, middle-click mutes, and a
// click opens the mixer: volume sliders, the output device list and the
// microphone.
Row {
    StatusRing {
        implicitWidth: 18
        implicitHeight: 18

        visible: AudioService.available
        // min(1, ...) so going past 100% doesn't make the arc wrap around
        value: Math.min(1, AudioService.volume)
        ringWidth: 4
        ringColor: AudioService.muted ? Theme.mutedText : Theme.accent

        onClicked: popup.toggle()
        onMiddleClicked: AudioService.toggleMute()
        onScrolled: delta => AudioService.changeVolume(delta)
    }

    // hangs below the ring (its Row is the anchor item)
    BarPopup {
        id: popup
        popupWidth: 300

        VolumeMixer {}
    }
}
