import QtQuick
import "../../../singletons"
import "../../../utils"

// A ring that shows a fraction (0.0 to 1.0) with an icon in the middle and a
// text next to it. The ring is green when low, the accent color in the middle
// and red when high (see Theme.usageColor). CpuIndicator and MemoryIndicator are
// built on this. Clicking anywhere on it (the ring or the text) emits `clicked`.
Item {
    id: root

    required property real resourceValue
    required property string iconText
    required property string iconFontFamily
    required property string outputText

    signal clicked

    implicitWidth: content.width
    implicitHeight: 26

    Row {
        id: content

        height: parent.height
        spacing: 6

        Item {
            width: 24
            height: 24
            anchors.verticalCenter: parent.verticalCenter

            StatusRing {
                anchors.fill: parent
                value: root.resourceValue
                ringColor: Theme.usageColor(root.resourceValue)
            }

            Text {
                anchors.centerIn: parent
                text: root.iconText
                color: Theme.primaryText
                font.family: root.iconFontFamily
                font.pixelSize: Fonts.labelTiny
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.outputText
            color: Theme.primaryText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.bodyMedium
            font.weight: Font.Light
        }
    }

    // Declared last, so it sits on top of everything above and a click on the ring
    // or on the text reaches it (the ring's own click handling is underneath).
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
