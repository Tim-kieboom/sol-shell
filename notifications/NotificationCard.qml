import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "../singletons"
import "../statusbar/components"

// One notification popup: the app's picture, who sent it, a title and the text.
// It closes itself after a while (see NotificationService.popupSeconds), pauses
// while the mouse is over it, and a click anywhere on it dismisses it.
Rectangle {
    id: root

    // The Notification object this card shows
    required property var notification

    readonly property bool critical: notification.urgency === NotificationUrgency.Critical
    readonly property bool low: notification.urgency === NotificationUrgency.Low
    // one of the shell's own error messages (see ShellMessages); real notifications
    // have no such property, which reads as undefined
    readonly property bool isError: notification.isError === true
    readonly property string picture: NotificationService.iconSource(notification)

    implicitHeight: content.implicitHeight + 24
    radius: 12
    color: Theme.shellBackground
    // a critical notification or an error gets a red, thicker border so it stands out
    border.width: critical || isError ? 2 : 1
    border.color: critical || isError ? Theme.danger : Theme.surfaceBorder
    // low-priority ones are a bit see-through: noticeable, but not pushy
    opacity: low ? 0.85 : 1.0

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        NotificationPicture {
            Layout.alignment: Qt.AlignTop
            source: root.picture
            glyph: root.isError ? Icons.alert : Icons.notifications
            critical: root.critical || root.isError
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.notification.appName
                visible: text !== ""
                color: Theme.secondaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelSmall
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.notification.summary
                color: Theme.primaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.bodyMedium
                font.weight: Font.Medium
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.notification.body
                color: Theme.secondaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.bodySmall
                wrapMode: Text.Wrap
                // a long message is cut off with "..." instead of making a huge popup
                maximumLineCount: 4
                elide: Text.ElideRight
            }
        }

        IconButton {
            Layout.alignment: Qt.AlignTop
            text: Icons.close
            onClicked: root.notification.dismiss()
        }
    }

    // ---------- closing ----------

    // Pointer handlers (new in Qt 6) listen without needing a MouseArea on top.
    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: root.notification.dismiss()
    }

    // Expire after the popup time. The time is 0 for "stay until dismissed", which
    // turns the timer off. It also stops while the mouse is over the card (so you
    // can finish reading) and starts again from zero when the mouse leaves.
    Timer {
        id: expiry
        interval: NotificationService.popupSeconds(root.notification) * 1000
        running: interval > 0 && !hover.hovered
        onTriggered: root.notification.expire()
    }

    // An app can update a notification it already sent (a download's progress, a
    // track change). Treat that as new, so it does not vanish mid-sentence.
    Connections {
        target: root.notification

        function onSummaryChanged() { expiry.restart(); }
        function onBodyChanged() { expiry.restart(); }
    }
}
