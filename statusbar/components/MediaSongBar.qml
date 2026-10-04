import QtQuick
import "../../singletons"

// The song title with a thin progress bar under it. Click the title (or scroll
// over it) to switch player when several have something to show; click the bar
// to seek.
Row {

    Item {
        anchors.verticalCenter: parent.verticalCenter
        width: title.width
        height: title.implicitHeight + 4

        Text {
            id: title
            // "Artist - Title", or only the title if the player gives no artist
            text: MediaService.artist !== "" ? MediaService.artist + " - " + MediaService.title : MediaService.title
            color: Theme.secondaryText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.bodyMedium
            elide: Text.ElideRight
            // long titles get cut off with "..." instead of pushing the bar wider
            width: Math.min(implicitWidth, 300)
        }

        // the track (full width, dim) ...
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 2
            radius: 1
            color: Theme.nonAccent

            // ... and the filled part, as wide as the song has progressed
            Rectangle {
                width: parent.width * MediaService.progress
                height: parent.height
                radius: parent.radius
                color: Theme.accent
            }
        }

        // Click or scroll over the title to switch player. Declared before the
        // seek area below, so the seek area sits on top of it.
        MouseArea {
            anchors.fill: parent
            enabled: MediaService.playerCount > 1
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: MediaService.selectRelative(1)
            // wheel up = previous player, wheel down = next
            onWheel: wheel => MediaService.selectRelative(wheel.angleDelta.y > 0 ? -1 : 1)
        }

        // Click the bar to seek. The visible bar is only 2px tall, far too thin
        // to hit, so this invisible strip is taller (10px) and covers it.
        // Being later in the file, it is drawn on top and gets the click first;
        // above it (the title) clicks still switch player.
        MouseArea {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 10
            // when disabled it ignores the mouse, so clicks fall through to the
            // switch-player area underneath
            enabled: MediaService.canSeek
            cursorShape: Qt.PointingHandCursor
            // mouse.x is pixels from the left edge; dividing by the width gives 0..1
            onClicked: mouse => MediaService.seekToFraction(mouse.x / width)
        }
    }
    // "1/2" badge, only when there is something to switch between
    Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: MediaService.playerCount > 1
        text: " " + (MediaService.currentIndex + 1) + "/" + MediaService.playerCount
        color: Theme.secondaryText
        font.family: Fonts.bodyFontFamily
        font.pixelSize: Fonts.labelSmall
    }
}
