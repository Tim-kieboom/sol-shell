import QtQuick
import "../singletons"

// The picture of a notification: the image or app icon, or a bell when there is
// none (or it failed to load). Used by the popup cards and the history rows.
Item {
    id: root

    // something an Image can load, or "" for none (see NotificationService.iconSource)
    property string source
    // what to draw when there is no picture (or it failed to load): a bell, or a
    // warning sign for the shell's own error messages
    property string glyph: Icons.notifications
    // a critical notification gets a red bell
    property bool critical: false

    implicitWidth: 40
    implicitHeight: 40

    Image {
        id: image
        anchors.fill: parent
        source: root.source
        // decode no bigger than shown (twice, for sharpness on scaled screens)
        sourceSize: Qt.size(root.width * 2, root.height * 2)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        visible: status === Image.Ready
    }

    Text {
        anchors.centerIn: parent
        visible: image.status !== Image.Ready
        text: root.glyph
        color: root.critical ? Theme.danger : Theme.accent
        font.family: Fonts.materialIconFontFamily
        font.pixelSize: root.height * 0.6
    }
}
