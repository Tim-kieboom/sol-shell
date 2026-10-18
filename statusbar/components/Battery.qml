import QtQuick
import QtQuick.Layouts
import "../../singletons"

// The battery: a glyph for how full it is and the percentage ("87%"), red when it is nearly empty and
// not charging, and the accent color while it charges. Click it for the details. It is not there on a
// machine without a battery (see BatteryService).
Item {
    id: root

    readonly property bool present: BatteryService.present
    visible: present

    implicitWidth: row.implicitWidth
    implicitHeight: 26

    readonly property color tint: BatteryService.low ? Theme.danger : (BatteryService.charging ? Theme.accentHover : Theme.accent)

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: BatteryService.icon
            color: mouse.containsMouse || popup.open ? Theme.accentHover : root.tint
            font.family: Fonts.materialIconFontFamily
            font.pixelSize: Fonts.bodyLarge
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: BatteryService.percent + "%"
            color: BatteryService.low ? Theme.danger : Theme.secondaryText
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
                        color: Theme.primaryText
                        font.family: Fonts.bodyFontFamily
                        font.pixelSize: Fonts.titleSmall
                        font.weight: Font.Medium
                    }

                    Text {
                        text: BatteryService.statusText
                        color: Theme.secondaryText
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
                color: Theme.surface

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
                        color: Theme.secondaryText
                        font.family: Fonts.bodyFontFamily
                        font.pixelSize: Fonts.bodySmall
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: modelData.value
                        color: Theme.primaryText
                        font.family: Fonts.bodyFontFamily
                        font.pixelSize: Fonts.bodySmall
                    }
                }
            }
        }
    }
}
