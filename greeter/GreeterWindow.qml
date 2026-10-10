import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../singletons"
import "../wallpaper"
import "../lock"

// The login screen: the same look as the lock screen (dimmed wallpaper, a big clock, a
// round password field), plus who is logging in and which session to start. The window is
// a plain one; the compositor it runs in (cage) makes it fill the screen.
FloatingWindow {
    id: root

    visible: true
    color: "black"
    title: "sol-shell login"

    // The module can point this at another picture; "" means the one that ships with sol-shell.
    // (Not the wallpaper setting: that lives in a user's home, and nobody is logged in yet.)
    WallpaperPicture {
        id: picture
        anchors.fill: parent
        path: Quickshell.env("SOL_SHELL_WALLPAPER") || ""
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.45
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    readonly property color textColor: "#ffffff"
    readonly property color softTextColor: "#c9ccd6"

    // a click anywhere gives the keyboard back to the field
    MouseArea {
        anchors.fill: parent
        onClicked: field.focusInput()
    }

    ColumnLayout {
        // like the lock screen: beside the shipped painting's face, centered otherwise
        x: picture.showingDefault ? root.width * 0.24 - width / 2 : (root.width - width) / 2
        y: (root.height - height) / 2
        spacing: 6

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatTime(clock.date, "HH:mm")
            color: root.textColor
            font.family: Fonts.bodyFontFamily
            font.pixelSize: 96
            font.weight: Font.Light
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDate(clock.date, "dddd d MMMM yyyy")
            color: root.softTextColor
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.titleLarge
        }

        Item {
            Layout.preferredHeight: 28
        }

        // who is logging in: one name, or a row of names to pick from
        Text {
            visible: GreeterService.users.length <= 1
            Layout.alignment: Qt.AlignHCenter
            text: GreeterService.userDisplay
            color: root.textColor
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.titleLarge
        }

        Row {
            visible: GreeterService.users.length > 1
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            Repeater {
                model: GreeterService.users

                Rectangle {
                    required property var modelData
                    required property int index

                    readonly property bool chosen: index === GreeterService.userIndex

                    width: name.implicitWidth + 24
                    height: 30
                    radius: height / 2
                    color: chosen ? Theme.accent : Qt.rgba(0, 0, 0, 0.45)
                    border.width: 1
                    border.color: chosen ? Theme.accent : Theme.surfaceBorder

                    Text {
                        id: name
                        anchors.centerIn: parent
                        text: parent.modelData.display
                        color: parent.chosen ? Theme.accentText : root.softTextColor
                        font.family: Fonts.bodyFontFamily
                        font.pixelSize: Fonts.bodyMedium
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            GreeterService.selectUser(parent.index);
                            field.focusInput();
                        }
                    }
                }
            }
        }

        PasswordField {
            id: field

            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 6
            text: GreeterService.typed
            error: GreeterService.error
            busy: GreeterService.checking

            onEdited: text => GreeterService.typed = text
            onSubmitted: GreeterService.submit()
            onCancelled: GreeterService.typed = ""
        }

        // "Wrong password" and the like; the space is always reserved so nothing jumps
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 24
            text: GreeterService.error !== "" ? GreeterService.error : GreeterService.notice
            color: GreeterService.error !== "" ? Theme.danger : root.softTextColor
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.bodyMedium
        }

        // the session to start; a click picks the next one when there are several
        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: GreeterService.session !== null
            text: GreeterService.session ? GreeterService.session.name + (GreeterService.sessions.length > 1 ? "  ▾" : "") : ""
            color: root.softTextColor
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.bodyMedium

            MouseArea {
                anchors.fill: parent
                enabled: GreeterService.sessions.length > 1
                cursorShape: Qt.PointingHandCursor
                onClicked: GreeterService.nextSession()
            }
        }

        // nothing to start: say so instead of leaving a field that does nothing
        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: GreeterService.sessions.length === 0
            text: "No session found in " + GreeterService.sessionsDir
            color: Theme.danger
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.bodyMedium
        }
    }

    // restart and shut down, bottom right
    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        spacing: 18

        Repeater {
            model: [
                { icon: Icons.restart, command: ["systemctl", "reboot"] },
                { icon: Icons.power, command: ["systemctl", "poweroff"] }
            ]

            Text {
                required property var modelData

                text: modelData.icon
                color: powerMouse.containsMouse ? Theme.accentHover : root.softTextColor
                font.family: Fonts.materialIconFontFamily
                font.pixelSize: 26

                MouseArea {
                    id: powerMouse
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached(parent.modelData.command)
                }
            }
        }
    }
}
