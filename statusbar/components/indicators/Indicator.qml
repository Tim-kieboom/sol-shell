import QtQuick
import "../../../singletons"
import "../../../utils"

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
                font.pixelSize: 10
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.outputText
            color: Theme.primaryText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: 14
            font.weight: Font.Light
        }
    }
}
