import QtQuick
import "../../singletons"

// Media controls for the bar: previous, play/pause, next, and the song title
// with its progress bar. Hidden when nothing is playing. Click the title for the media
// popup (the cover, the time, shuffle and repeat, and a list of players). Compact (see
// the bar styles): only the three buttons and a note that opens the popup, with no title,
// no progress bar and no separators.
Item {
    id: root

    // only the buttons (set by the bar style)
    property bool compact: false

    // Hidden when nothing is playing. A hidden item in a layout also takes
    // up no space, so the rest of the bar closes the gap by itself. `present` is
    // how BarRenderer finds out (it cannot ask `visible`).
    readonly property bool present: MediaService.available
    visible: present

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row

        spacing: 6

        Separator {
            visible: !root.compact
        }
        MediaSongBar {
            visible: !root.compact
            onTitleClicked: popup.toggle()
        }

        // With no title to click in the compact bar, a note opens the popup
        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.compact
            text: Icons.media
            onClicked: popup.toggle()
        }

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

        Separator {
            visible: !root.compact
        }
    }

    // hangs below the media controls (the popup is anchored to this item)
    BarPopup {
        id: popup
        popupWidth: 340

        MediaPopup {}
    }
}
