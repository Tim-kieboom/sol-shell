import QtQuick
import QtQuick.Layouts
import "../singletons"

// The rounded password field of the lock screen and the login screen: dots for the
// letters, a check button, and a shake when the password was wrong. It only reports what
// happens (`edited`, `submitted`, `cancelled`); the owner holds the text, so several
// monitors can show the same dots.
//
// The colors are fixed (light on dark), because the screen behind it is always dimmed to
// dark, whatever the theme.
Rectangle {
    id: root

    // what is typed
    property string text: ""
    // why the last try failed, or ""; the border turns red and the field shakes
    property string error: ""
    // true while the password is being checked: nothing can be typed
    property bool busy: false
    property string placeholder: "Password"

    signal edited(string text)
    signal submitted
    signal cancelled

    readonly property color textColor: "#ffffff"
    readonly property color hintColor: "#8f93a3"

    // give the keyboard to the field
    function focusInput(): void {
        input.forceActiveFocus();
    }

    implicitWidth: 320
    implicitHeight: 46
    radius: height / 2
    color: Qt.rgba(0, 0, 0, 0.55)
    border.width: 1
    border.color: error !== "" ? Theme.danger
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

    onErrorChanged: {
        if (error !== "")
            shakeAnimation.restart();
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
            readOnly: root.busy
            text: root.text
            color: root.textColor
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.bodyLarge
            selectionColor: Theme.accent
            selectedTextColor: "#ffffff"

            onTextEdited: root.edited(text)
            // Enter checks the password, Escape wipes what was typed
            onAccepted: root.submitted()
            Keys.onEscapePressed: root.cancelled()

            // the keyboard goes to the field as soon as it is shown
            Component.onCompleted: forceActiveFocus()

            // placeholder: shown only while the field is empty
            Text {
                visible: input.text === ""
                anchors.verticalCenter: parent.verticalCenter
                text: root.busy ? "Checking..." : root.placeholder
                color: root.hintColor
                font: input.font
            }
        }

        // Enter works too; this is for the mouse
        Text {
            text: Icons.confirm
            color: root.text !== "" && !root.busy ? Theme.accent : root.hintColor
            font.family: Fonts.materialIconFontFamily
            font.pixelSize: Fonts.titleLarge

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.submitted()
            }
        }
    }
}
