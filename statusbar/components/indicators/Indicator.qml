import QtQuick
import "../../../singletons"
import "../../../utils"

// A ring that shows a fraction (0.0 to 1.0) with an icon in the middle and a
// text next to it. The ring is green when low, the accent color in the middle
// and red when high (see indicatorColor). CpuIndicator and MemoryIndicator are
// built on this.
Item {
    id: root

    required property real resourceValue
    required property string iconText
    required property string iconFontFamily
    required property string outputText

    // Passed through from the ring. Indicators that don't care (CPU, memory)
    // simply never attach a handler, so nothing changes for them.
    signal scrolled(real delta)
    signal clicked

    implicitWidth: content.width
    implicitHeight: 26

    function indicatorColor() {
        const usage = root.resourceValue;
        if (usage < 0.5) {
            return Theme.success;
        } else if (usage < 0.8) {
            return Theme.accent;
        } else {
            return Theme.danger;
        }
    }

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
                ringColor: root.indicatorColor()
                onScrolled: delta => root.scrolled(delta)
                onClicked: root.clicked()
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
}
