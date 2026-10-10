import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../singletons"
import "../wallpaper"

// What the lock shows on one monitor: the wallpaper (dimmed), a big clock and a password
// field. WlSessionLock makes one of these for every monitor. The text typed lives in
// LockService, so whichever monitor has the keyboard, they all show the same dots.
WlSessionLockSurface {
    id: root

    color: "black"

    WallpaperPicture {
        id: picture
        anchors.fill: parent
    }

    // dims the wallpaper so the clock and the field read well on any picture
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.45
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // The wallpaper is always dimmed to dark, so the text is always light, whatever the theme
    // (a light theme's own text color would vanish on it).
    readonly property color textColor: "#ffffff"
    readonly property color softTextColor: "#c9ccd6"
    readonly property color hintColor: "#8f93a3"

    // a click anywhere gives the keyboard back to the field
    MouseArea {
        anchors.fill: parent
        onClicked: input.forceActiveFocus()
    }

    ColumnLayout {
        // Centered, except over the shipped painting: its face is in the middle, so the clock
        // and the field go in the dark space to its left (on a landscape monitor).
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
            Layout.preferredHeight: 36
        }

        // the password field: a box we draw, with the bare TextInput inside, like the Wi-Fi
        // password prompt
        Rectangle {
            id: field

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 320
            Layout.preferredHeight: 46
            radius: height / 2
            color: Qt.rgba(0, 0, 0, 0.55)
            border.width: 1
            border.color: LockService.error !== "" ? Theme.danger
                : input.activeFocus ? Theme.accent : Theme.surfaceBorder

            // a wrong password shakes the field
            transform: Translate {
                id: shake
            }

            SequentialAnimation {
                id: shakeAnimation

                NumberAnimation { target: shake; property: "x"; to: -14; duration: 50 }
                NumberAnimation { target: shake; property: "x"; to: 14; duration: 90 }
                NumberAnimation { target: shake; property: "x"; to: -8; duration: 80 }
                NumberAnimation { target: shake; property: "x"; to: 0; duration: 60 }
            }

            Connections {
                target: LockService

                function onErrorChanged(): void {
                    if (LockService.error !== "")
                        shakeAnimation.restart();
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 14
                spacing: 8

                TextInput {
                    id: input

                    Layout.fillWidth: true
                    clip: true
                    focus: true
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    // nothing can be typed while PAM is still checking the last try
                    readOnly: LockService.checking
                    text: LockService.typed
                    color: root.textColor
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.bodyLarge
                    selectionColor: Theme.accent
                    selectedTextColor: "#ffffff"

                    onTextEdited: LockService.typed = text
                    // Enter checks the password, Escape wipes what was typed
                    onAccepted: LockService.submit()
                    Keys.onEscapePressed: LockService.typed = ""

                    // the keyboard goes to the field as soon as the lock is shown
                    Component.onCompleted: forceActiveFocus()

                    // placeholder: shown only while the field is empty
                    Text {
                        visible: input.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: LockService.checking ? "Checking..." : "Password"
                        color: root.hintColor
                        font: input.font
                    }
                }

                // Enter works too; this is for the mouse
                Text {
                    text: Icons.confirm
                    color: LockService.typed !== "" && !LockService.checking ? Theme.accent : root.hintColor
                    font.family: Fonts.materialIconFontFamily
                    font.pixelSize: Fonts.titleLarge

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: LockService.submit()
                    }
                }
            }
        }

        // "Wrong password" and the like; the space is always reserved so the clock does not
        // jump when it appears
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 24
            text: LockService.error
            color: Theme.danger
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.bodyMedium
        }
    }
}
