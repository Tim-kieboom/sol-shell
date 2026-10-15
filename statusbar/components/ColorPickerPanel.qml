import QtQuick
import QtQuick.Layouts
import "../../singletons"
import "../../utils"

// The color picker's panel: a hex field with a swatch, red, green and blue sliders, and an
// eyedropper. It is what the color picker atom's popup shows, and one page of the quick
// settings menu. The state lives in a ColorPickerState, because the panel is thrown away
// whenever its popup closes, and a picked color has to survive that.
ColumnLayout {
    id: root

    // the state: what is typed, the color it makes, the channels (see ColorPickerState)
    required property var picker
    // the eyedropper was clicked: whoever shows this panel closes it, so the screen can be
    // picked from
    signal closeRequested

    spacing: 8

    RowLayout {
        spacing: 10

        // the color that is typed in the field
        Rectangle {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            radius: 8
            color: picker.color !== "" ? picker.color : Theme.surface
            border.width: 1
            border.color: Theme.surfaceBorder

            Text {
                visible: picker.color === ""
                anchors.centerIn: parent
                text: "?"
                color: Theme.mutedText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.bodyLarge
            }
        }

        // the field: a box we draw, with the bare TextInput inside (as in the Wi-Fi
        // password prompt)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: 8
            color: Theme.shellBackground
            border.width: 1
            // red while what is typed cannot be a color
            border.color: input.text !== "" && picker.color === "" ? Theme.danger
                : input.activeFocus ? Theme.accent : Theme.surfaceBorder

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 8
                spacing: 6

                TextInput {
                    id: input
                    Layout.fillWidth: true
                    clip: true
                    // "#" and six digits
                    maximumLength: 7
                    text: picker.input
                    color: Theme.primaryText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.bodyMedium
                    selectByMouse: true
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.accentText

                    onTextEdited: picker.input = text
                    // Enter tidies the text up: "C8A96A" becomes "#c8a96a"
                    onAccepted: if (picker.color !== "") picker.input = picker.color

                    // the keyboard goes to the field as soon as the popup opens
                    Component.onCompleted: forceActiveFocus()

                    // placeholder: shown only while the field is empty
                    Text {
                        visible: input.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "#rrggbb"
                        color: Theme.mutedText
                        font: input.font
                    }
                }

                // the eyedropper: close the popup so the screen can be picked from;
                // the picked color comes back into the field (see onPicked above)
                Text {
                    text: Icons.eyedropper
                    color: ColorPickerService.picking ? Theme.mutedText : Theme.accent
                    font.family: Fonts.materialIconFontFamily
                    font.pixelSize: Fonts.bodyLarge

                    MouseArea {
                        anchors.fill: parent
                        enabled: !ColorPickerService.picking
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.closeRequested();
                            ColorPickerService.pick();
                        }
                    }
                }
            }
        }
    }

    // red, green and blue: a label, the slider, and the number
    Repeater {
        model: [
            { label: "R", tint: "#e05561" },
            { label: "G", tint: "#5fbf6a" },
            { label: "B", tint: "#5b8def" }
        ]

        RowLayout {
            id: channelRow

            required property int index
            required property var modelData

            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.preferredWidth: 12
                text: channelRow.modelData.label
                color: Theme.secondaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelMedium
            }

            VolumeSlider {
                Layout.fillWidth: true
                fillColor: channelRow.modelData.tint
                value: picker.channels[channelRow.index] / 255
                onMoved: fraction => picker.setChannel(channelRow.index, fraction)
            }

            Text {
                // a fixed width, so the slider does not change length with the number
                Layout.preferredWidth: 26
                horizontalAlignment: Text.AlignRight
                text: picker.channels[channelRow.index]
                color: Theme.secondaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelMedium
            }
        }
    }

    Text {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: input.text !== "" && picker.color === ""
            ? "That is not a hex color. Use 6 digits, like #c8a96a."
            : "Type a hex code, move the sliders, or pick a color from the screen with the eyedropper."
        color: input.text !== "" && picker.color === "" ? Theme.danger : Theme.mutedText
        font.family: Fonts.bodyFontFamily
        font.pixelSize: Fonts.labelSmall
    }
}
