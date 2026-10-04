import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "../singletons"
import "../statusbar/components"

// One line in the notification history. `entry` is one item of
// NotificationService.history (a plain copy, the notification itself is long gone).
Rectangle {
    id: root

    required property var entry
    // the current time, from a clock that ticks, so "5 min ago" keeps up
    required property date now

    readonly property bool critical: entry.urgency === NotificationUrgency.Critical

    implicitHeight: content.implicitHeight + 16
    radius: 10
    color: hover.hovered ? Theme.surface : "transparent"
    // critical entries keep their red edge, so they are easy to find in a long list
    border.width: critical ? 1 : 0
    border.color: Theme.danger

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 8
        spacing: 10

        NotificationPicture {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 32
            implicitHeight: 32
            source: root.entry.picture
            critical: root.critical
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            // "Brave · 5 min ago"
            Text {
                Layout.fillWidth: true
                text: (root.entry.appName !== "" ? root.entry.appName + "  ·  " : "")
                    + NotificationService.relativeTime(root.entry.time, root.now)
                color: Theme.secondaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelSmall
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.entry.summary
                color: Theme.primaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.bodySmall
                font.weight: Font.Medium
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.entry.body
                color: Theme.secondaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelMedium
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }

        // remove this one entry from the history
        IconButton {
            Layout.alignment: Qt.AlignTop
            text: Icons.close
            onClicked: NotificationService.remove(root.entry.id)
        }
    }

    HoverHandler {
        id: hover
    }
}
