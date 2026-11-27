import QtQuick
import QtQuick.Layouts
import "../../singletons"

// The battery: a glyph for how full it is and the percentage ("87%"), red when it is nearly empty and
// not charging, and the accent color while it charges. Click it for the details. It is not there on a
// machine without a battery (see BatteryService).
Item {
    // this monitor's colors
    readonly property var theme: Theme.forScreen(Window.window?.screen?.name ?? "")
    id: root

    readonly property bool present: BatteryService.present
    visible: present

    implicitWidth: row.implicitWidth
    implicitHeight: 26

    readonly property color tint: BatteryService.low ? theme.danger : (BatteryService.charging ? theme.accentHover : theme.accent)

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: BatteryService.icon
            color: mouse.containsMouse || popup.open ? theme.accentHover : root.tint
            font.family: Fonts.materialIconFontFamily
            font.pixelSize: Fonts.bodyLarge
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: BatteryService.percent + "%"
            color: BatteryService.low ? theme.danger : theme.secondaryText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.bodyMedium
            font.weight: Font.Medium
        }
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

        ColumnLayout {
            spacing: 8

            RowLayout {
                spacing: 10

                Text {
                    text: BatteryService.icon
                    color: root.tint
                    font.family: Fonts.materialIconFontFamily
                    font.pixelSize: Fonts.headlineMedium
                }

                ColumnLayout {
                    spacing: 0

                    Text {
                        text: BatteryService.percent + "%"
                        color: theme.primaryText
                        font.family: Fonts.bodyFontFamily
                        font.pixelSize: Fonts.titleSmall
                        font.weight: Font.Medium
                    }

                    Text {
                        text: BatteryService.statusText
                        color: theme.secondaryText
                        font.family: Fonts.bodyFontFamily
                        font.pixelSize: Fonts.bodySmall
                    }
                }
            }

            // a bar for the charge
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 6
                radius: 3
                color: theme.surface

                Rectangle {
                    width: parent.width * BatteryService.percent / 100
                    height: parent.height
                    radius: 3
                    color: root.tint
                }
            }

            Repeater {
                model: [
                    {
                        label: "Time",
                        value: BatteryService.timeText
                    },
                    {
                        label: "Power",
                        value: BatteryService.powerText
                    },
                    {
                        label: "Health",
                        value: BatteryService.device?.healthSupported ? Math.round(BatteryService.device.healthPercentage) + "%" : ""
                    }
                ]

                RowLayout {
                    required property var modelData

                    Layout.fillWidth: true
                    visible: modelData.value !== ""

                    Text {
                        text: modelData.label
                        color: theme.secondaryText
                        font.family: Fonts.bodyFontFamily
                        font.pixelSize: Fonts.bodySmall
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: modelData.value
                        color: theme.primaryText
                        font.family: Fonts.bodyFontFamily
                        font.pixelSize: Fonts.bodySmall
                    }
                }
            }
        }
    }
}
