import QtQuick
import QtQuick.Layouts
import "../../singletons"

// How full the system disk is ("58%"; red from 90%). Click it for every disk, with how much is free.
Item {
    // this monitor's colors
    readonly property var theme: Theme.forScreen(Window.window?.screen?.name ?? "")
    id: root

    // nothing to show until `df` has answered
    readonly property bool present: DiskService.main !== null
    visible: present

    implicitWidth: row.implicitWidth
    implicitHeight: 26

    readonly property bool warn: (DiskService.main?.fraction ?? 0) >= DiskService.warnFraction

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Icons.disk
            color: root.warn ? theme.danger : (mouse.containsMouse || popup.open ? theme.accentHover : theme.accent)
            font.family: Fonts.materialIconFontFamily
            font.pixelSize: Fonts.bodyLarge
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round((DiskService.main?.fraction ?? 0) * 100) + "%"
            color: root.warn ? theme.danger : theme.secondaryText
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
        popupWidth: 300

        // fresh figures whenever someone looks
        onOpenChanged: {
            if (open)
                DiskService.refresh();
        }

        ColumnLayout {
            spacing: 12

            Repeater {
                model: DiskService.disks

                ColumnLayout {
                    required property var modelData

                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: modelData.mount
                            color: theme.primaryText
                            font.family: Fonts.bodyFontFamily
                            font.pixelSize: Fonts.bodyMedium
                            font.weight: Font.Medium
                        }

                        // the device, as `nvme0n1p7` and not `/dev/nvme0n1p7`
                        Text {
                            text: modelData.source.split("/").pop()
                            color: theme.mutedText
                            font.family: Fonts.bodyFontFamily
                            font.pixelSize: Fonts.bodySmall
                            leftPadding: 6
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            text: Math.round(modelData.fraction * 100) + "%"
                            color: modelData.fraction >= DiskService.warnFraction ? theme.danger : theme.secondaryText
                            font.family: Fonts.bodyFontFamily
                            font.pixelSize: Fonts.bodyMedium
                        }
                    }

                    // the bar: how much of the disk is used
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        radius: 3
                        color: theme.surface

                        Rectangle {
                            width: parent.width * modelData.fraction
                            height: parent.height
                            radius: 3
                            color: modelData.fraction >= DiskService.warnFraction ? theme.danger : theme.accent
                        }
                    }

                    Text {
                        text: DiskService.formatBytes(modelData.used) + " used, " + DiskService.formatBytes(modelData.avail) + " free of " + DiskService.formatBytes(modelData.size)
                        color: theme.mutedText
                        font.family: Fonts.bodyFontFamily
                        font.pixelSize: Fonts.bodySmall
                    }
                }
            }
        }
    }
}
