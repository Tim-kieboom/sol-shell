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

    // a click anywhere gives the keyboard back to the field
    MouseArea {
        anchors.fill: parent
        onClicked: field.focusInput()
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

        PasswordField {
            id: field

            Layout.alignment: Qt.AlignHCenter
            text: LockService.typed
            error: LockService.error
            busy: LockService.checking

            onEdited: text => LockService.typed = text
            onSubmitted: LockService.submit()
            onCancelled: LockService.typed = ""
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
