import QtQuick
import QtQuick.Layouts
import "../../singletons"

// One line in the power menu. `action` is one entry of PowerService.actions.
Rectangle {
    id: root

    required property var action

    // Dangerous actions (shut down, ...) need a second click. Harmless entries,
    // like "Settings", turn this off and just emit `activated` on the first click.
    property bool needsConfirm: true
    signal activated

    // true after the first click, while we wait for the confirming second click
    readonly property bool armed: needsConfirm && PowerService.pendingId === root.action.id

    implicitHeight: 40
    radius: 8
    // armed rows turn red-ish so it is obvious something is about to happen
    color: armed ? Theme.withOpacity(Theme.danger, 0.2) : mouse.containsMouse ? Theme.nonAccent : "transparent"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 12

        Text {
            text: root.action.icon
            color: root.armed ? Theme.danger : Theme.accent
            font.family: Fonts.materialIconFontFamily
            font.pixelSize: Fonts.titleMedium
        }

        Column {
            Layout.fillWidth: true

            Text {
                text: root.action.label
                color: Theme.primaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.bodyMedium
            }

            // the hint only exists (and only takes space) while armed
            Text {
                visible: root.armed
                text: "Click again to confirm"
                color: Theme.danger
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelSmall
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.needsConfirm)
                PowerService.activate(root.action);
            else
                root.activated();
        }
    }
}
