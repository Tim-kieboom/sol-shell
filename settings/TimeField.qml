import QtQuick
import QtQuick.Layouts
import "../singletons"

// A time of day as "HH:MM". Type it, or move it a quarter of an hour with the buttons (past midnight
// it goes round). It only reports the new time (`committed`); the owner saves it, and sets `value` from
// what is saved, so the field always shows what is true.
RowLayout {
    id: root

    property string value: "00:00"
    signal committed(string text)

    spacing: 6

    // a quarter of an hour earlier (-15) or later (15)
    function step(delta: int): void {
        const now = NightLightService.minutesOf(root.value);
        root.committed(NightLightService.timeText((now < 0 ? 0 : now) + delta));
    }

    // when what is saved changes (a step, or the file was edited), the field follows
    onValueChanged: input.text = root.value

    Rectangle {
        Layout.preferredWidth: 28
        Layout.preferredHeight: 28
        radius: 8
        color: lessMouse.containsMouse ? Theme.surface : "transparent"
        border.width: 1
        border.color: Theme.surfaceBorder

        Text {
            anchors.centerIn: parent
            text: "−"
            color: Theme.primaryText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.bodyLarge
        }

        MouseArea {
            id: lessMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.step(-15)
        }
    }

    Rectangle {
        Layout.preferredWidth: 64
        Layout.preferredHeight: 28
        radius: 8
        color: Theme.shellBackground
        border.width: 1
        // red while what is typed is not a time of day
        border.color: NightLightService.minutesOf(input.text) < 0 ? Theme.danger : input.activeFocus ? Theme.accent : Theme.surfaceBorder

        TextInput {
            id: input
            anchors.fill: parent
            anchors.margins: 4
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter
            maximumLength: 5
            text: root.value
            color: Theme.primaryText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.bodyMedium
            selectByMouse: true
            selectionColor: Theme.accent
            selectedTextColor: Theme.accentText

            // Enter or leaving the field: a time is saved (as "07:05"), anything else is put back
            onEditingFinished: {
                const minutes = NightLightService.minutesOf(text);
                if (minutes >= 0)
                    root.committed(NightLightService.timeText(minutes));
                else
                    text = root.value;
            }
        }
    }

    Rectangle {
        Layout.preferredWidth: 28
        Layout.preferredHeight: 28
        radius: 8
        color: moreMouse.containsMouse ? Theme.surface : "transparent"
        border.width: 1
        border.color: Theme.surfaceBorder

        Text {
            anchors.centerIn: parent
            text: "+"
            color: Theme.primaryText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.bodyLarge
        }

        MouseArea {
            id: moreMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.step(15)
        }
    }
}
