import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import "../../singletons"
import "../../utils"

// The contents of the media popup: the cover, what is playing (title, artist, album and the
// player), a bar to seek along with the time, the buttons (shuffle, previous, play and pause,
// next, repeat) and, when several players have something to show, a list to pick one.
ColumnLayout {
    id: root

    spacing: 12

    // ---------- what is playing ----------
    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        // The cover. A player may give none, or one that cannot be loaded (no network): the
        // frame then shows a note, so the popup does not look broken.
        Rectangle {
            Layout.preferredWidth: 76
            Layout.preferredHeight: 76
            Layout.alignment: Qt.AlignTop
            radius: 8
            color: Theme.surface
            clip: true

            Image {
                id: cover
                anchors.fill: parent
                source: MediaService.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                // decode at the size it is shown (twice that, for sharp edges), not at the
                // size of a 3000-pixel cover
                sourceSize.width: 152
                sourceSize.height: 152
                visible: status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                visible: cover.status !== Image.Ready
                text: Icons.emptyMedia
                color: Theme.mutedText
                font.family: Fonts.materialIconFontFamily
                font.pixelSize: Fonts.headlineMedium
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: MediaService.title
                color: Theme.primaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.bodyMedium
                font.weight: Font.Medium
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: MediaService.artist
                color: Theme.secondaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.bodySmall
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: MediaService.album
                color: Theme.mutedText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelSmall
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 4
                visible: text !== ""
                text: MediaService.identity
                color: Theme.accent
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelSmall
                elide: Text.ElideRight
            }
        }
    }

    // ---------- the time ----------
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        // While the bar is dragged, `draft` holds the place under the pointer; -1 means "not
        // dragging". The player is told only when the pointer has rested a moment (see
        // seekTimer): a drag makes dozens of changes a second, and every one would be a seek.
        QtObject {
            id: seek
            property real draft: -1
            readonly property real shown: draft >= 0 ? draft : MediaService.progress
        }

        Timer {
            id: seekTimer
            interval: 150
            onTriggered: {
                MediaService.seekToFraction(seek.draft);
                seek.draft = -1;
            }
        }

        VolumeSlider {
            Layout.fillWidth: true
            // a player that cannot seek (a live stream) shows the bar, but it does nothing
            enabled: MediaService.canSeek
            opacity: enabled ? 1.0 : 0.45
            value: seek.shown
            onMoved: fraction => {
                seek.draft = fraction;
                seekTimer.restart();
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: MediaService.formatTime(seek.shown * MediaService.durationSeconds)
                color: Theme.secondaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelSmall
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                // a stream has no length: say so with a dash
                text: MediaService.durationSeconds > 0 ? MediaService.formatTime(MediaService.durationSeconds) : "–"
                color: Theme.secondaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelSmall
            }
        }
    }

    // ---------- the buttons ----------
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 20

        // a player without shuffle or repeat keeps the space, so the buttons stay in the middle
        IconButton {
            opacity: MediaService.shuffleSupported ? 1.0 : 0.0
            enabled: MediaService.shuffleSupported
            text: MediaService.shuffling ? Icons.shuffle : Icons.shuffleOff
            // lit while shuffling, dim while not
            color: MediaService.shuffling ? Theme.accent : Theme.secondaryText
            onClicked: MediaService.toggleShuffle()
        }

        IconButton {
            text: Icons.previousTrack
            enabled: MediaService.canGoPrevious
            font.pixelSize: Fonts.titleLarge
            onClicked: MediaService.previous()
        }

        IconButton {
            // the action a click will do: pause while playing, play while paused
            text: MediaService.playing ? Icons.pause : Icons.play
            enabled: MediaService.canTogglePlaying
            font.pixelSize: Fonts.headlineMedium
            onClicked: MediaService.playPause()
        }

        IconButton {
            text: Icons.nextTrack
            enabled: MediaService.canGoNext
            font.pixelSize: Fonts.titleLarge
            onClicked: MediaService.next()
        }

        IconButton {
            opacity: MediaService.loopSupported ? 1.0 : 0.0
            enabled: MediaService.loopSupported
            text: MediaService.loopState === MprisLoopState.Track ? Icons.repeatOne
                : MediaService.loopState === MprisLoopState.Playlist ? Icons.repeatAll : Icons.repeatOff
            color: MediaService.loopState === MprisLoopState.None ? Theme.secondaryText : Theme.accent
            onClicked: MediaService.cycleLoop()
        }
    }

    // ---------- the players ----------
    // Only when there is a choice. A click on one makes it the one the bar follows.
    ColumnLayout {
        Layout.fillWidth: true
        visible: MediaService.playerCount > 1
        spacing: 2

        Rectangle {
            Layout.fillWidth: true
            Layout.bottomMargin: 4
            height: 1
            color: Theme.surfaceBorder
        }

        Repeater {
            model: ScriptModel {
                values: MediaService.players
            }

            ListRow {
                required property var modelData

                Layout.fillWidth: true
                icon: modelData.isPlaying ? Icons.media : Icons.emptyMedia
                title: modelData.identity
                subtitle: modelData.trackTitle
                highlighted: modelData.dbusName === MediaService.currentPlayer?.dbusName
                onClicked: MediaService.selectPlayer(modelData)
            }
        }
    }
}
