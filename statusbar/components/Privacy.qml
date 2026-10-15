import QtQuick
import QtQuick.Layouts
import "../../singletons"

// An icon for each thing that is being watched or listened to right now: the microphone, the camera, the
// screen (see PrivacyService). It is not there when nothing is. Click it for a list of which programs.
Item {
    id: root

    // there is nothing to show when nothing is in use; `present` is how BarRenderer finds out
    readonly property bool present: PrivacyService.anyActive
    visible: present

    implicitWidth: icons.implicitWidth
    implicitHeight: 26

    Row {
        id: icons
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        // one icon for each kind that is in use, in the red the bar uses for danger. They are written
        // out one by one (not made by a Repeater from a list): a Row did not take the size of icons
        // made that way.
        Text {
            visible: PrivacyService.microphone.length > 0
            text: Icons.microphone
            color: Theme.danger
            font.family: Fonts.materialIconFontFamily
            font.pixelSize: Fonts.bodyLarge
        }

        Text {
            visible: PrivacyService.camera.length > 0
            text: Icons.camera
            color: Theme.danger
            font.family: Fonts.materialIconFontFamily
            font.pixelSize: Fonts.bodyLarge
        }

        Text {
            visible: PrivacyService.screen.length > 0
            text: Icons.screenShare
            color: Theme.danger
            font.family: Fonts.materialIconFontFamily
            font.pixelSize: Fonts.bodyLarge
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.toggle()
    }

    BarPopup {
        id: popup

        // near the right end of the bar: grow leftwards
        alignRight: true
        popupWidth: 280

        ColumnLayout {
            spacing: 10

            Repeater {
                model: [
                    {
                        icon: Icons.microphone,
                        title: "Microphone",
                        apps: PrivacyService.microphone
                    },
                    {
                        icon: Icons.camera,
                        title: "Camera",
                        apps: PrivacyService.camera
                    },
                    {
                        icon: Icons.screenShare,
                        title: "Screen",
                        apps: PrivacyService.screen
                    }
                ]

                ColumnLayout {
                    required property var modelData

                    Layout.fillWidth: true
                    visible: modelData.apps.length > 0
                    spacing: 2

                    RowLayout {
                        spacing: 8

                        Text {
                            text: modelData.icon
                            color: Theme.danger
                            font.family: Fonts.materialIconFontFamily
                            font.pixelSize: Fonts.titleSmall
                        }

                        Text {
                            text: modelData.title
                            color: Theme.primaryText
                            font.family: Fonts.bodyFontFamily
                            font.pixelSize: Fonts.bodyMedium
                            font.weight: Font.Medium
                        }
                    }

                    Repeater {
                        model: modelData.apps

                        Text {
                            required property string modelData
                            Layout.leftMargin: 28
                            text: modelData
                            color: Theme.secondaryText
                            font.family: Fonts.bodyFontFamily
                            font.pixelSize: Fonts.bodySmall
                        }
                    }
                }
            }
        }
    }
}
