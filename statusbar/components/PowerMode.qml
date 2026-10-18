import QtQuick
import QtQuick.Layouts
import "../../singletons"

// The power mode in use (a leaf for power saver, scales for balanced, a rocket for performance). Click
// it to pick another. It is only there on a machine with a battery, which is where it matters.
Item {
    id: root

    readonly property bool present: BatteryService.present
    visible: present

    implicitWidth: 26
    implicitHeight: 26

    Text {
        anchors.centerIn: parent
        text: PowerModeService.current.icon
        color: mouse.containsMouse || popup.open ? Theme.accentHover : Theme.accent
        font.family: Fonts.materialIconFontFamily
        font.pixelSize: Fonts.bodyLarge
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.toggle()
    }

    BarPopup {
        id: popup

        alignRight: true
        popupWidth: 260
        padding: 8

        ColumnLayout {
            spacing: 2

            Repeater {
                model: PowerModeService.available

                ListRow {
                    required property var modelData

                    Layout.fillWidth: true
                    icon: modelData.icon
                    title: modelData.title
                    subtitle: modelData.subtitle
                    highlighted: modelData.value === PowerModeService.profile
                    onClicked: {
                        PowerModeService.set(modelData);
                        popup.close();
                    }

                    // a tick on the one in use
                    Text {
                        visible: parent.highlighted
                        text: Icons.confirm
                        color: Theme.accent
                        font.family: Fonts.materialIconFontFamily
                        font.pixelSize: Fonts.bodyLarge
                    }
                }
            }

            Text {
                visible: PowerModeService.degradedText !== ""
                Layout.fillWidth: true
                Layout.margins: 8
                wrapMode: Text.WordWrap
                text: PowerModeService.degradedText
                color: Theme.mutedText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.bodySmall
            }
        }
    }
}
