import QtQuick
import "../../singletons"

// How fast data is coming in and going out right now: "↓ 1.2 MB/s ↑ 40 KB/s" (see
// NetworkSpeedService). There is nothing to click. It is always as wide as its widest reading, so the
// items next to it do not shift every two seconds.
Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: 26

    // the service reads /proc only while an item like this exists
    Component.onCompleted: NetworkSpeedService.viewerCount += 1
    Component.onDestruction: NetworkSpeedService.viewerCount -= 1

    // the widest thing a speed can say ("999 KB/s"), to size the two figures by
    TextMetrics {
        id: widest
        font.family: Fonts.bodyFontFamily
        font.pixelSize: Fonts.bodyMedium
        font.weight: Font.Medium
        text: "999 KB/s"
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Row {
            spacing: 2

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.arrowDown
                color: Theme.accent
                font.family: Fonts.materialIconFontFamily
                font.pixelSize: Fonts.bodyMedium
            }

            Text {
                width: widest.width
                horizontalAlignment: Text.AlignRight
                text: NetworkSpeedService.known ? NetworkSpeedService.formatRate(NetworkSpeedService.downSpeed) : "-"
                color: Theme.secondaryText
                font: widest.font
            }
        }

        Row {
            spacing: 2

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.arrowUp
                color: Theme.accent
                font.family: Fonts.materialIconFontFamily
                font.pixelSize: Fonts.bodyMedium
            }

            Text {
                width: widest.width
                horizontalAlignment: Text.AlignRight
                text: NetworkSpeedService.known ? NetworkSpeedService.formatRate(NetworkSpeedService.upSpeed) : "-"
                color: Theme.secondaryText
                font: widest.font
            }
        }
    }
}
