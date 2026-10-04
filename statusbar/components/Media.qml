import QtQuick
import "../../singletons"

// Media controls for the bar: previous, play/pause, next, and the song title
// with its progress bar. Hidden when nothing is playing.
Row {
    // Hidden when nothing is playing. A hidden item in a layout also takes
    // up no space, so the rest of the bar closes the gap by itself.
    visible: MediaService.available
    spacing: 6

    Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -2
        text: "|"
        font.pixelSize: 20
        color: Theme.accent
    }
    MediaSongBar {}

    IconButton {
        anchors.verticalCenter: parent.verticalCenter
        text: Icons.previousTrack
        enabled: MediaService.canGoPrevious
        onClicked: MediaService.previous()
    }

    IconButton {
        anchors.verticalCenter: parent.verticalCenter
        // shows the action a click will perform: pause while playing, play while paused
        text: MediaService.playing ? Icons.pause : Icons.play
        enabled: MediaService.canTogglePlaying
        onClicked: MediaService.playPause()
    }

    IconButton {
        anchors.verticalCenter: parent.verticalCenter
        text: Icons.nextTrack
        enabled: MediaService.canGoNext
        onClicked: MediaService.next()
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -2
        text: "|"
        font.pixelSize: 20
        color: Theme.accent
    }
}
