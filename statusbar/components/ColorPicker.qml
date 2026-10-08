import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "../../singletons"
import "../../utils"

// The palette button in the bar. Click it for a small popup with a hex field: type a code
// (#c8a96a, c8a96a or #ca6) and the swatch beside it shows the color, or move the red,
// green and blue sliders below it, which change the same field. The eyedropper in the
// field picks a color from anywhere on the screen instead, and the result is filled in
// on the same field. The picker can also be started from a keybind
// (`sol-shell ipc call picker pick`); the popup then opens on the monitor you are using.
Item {
    id: root

    // the monitor this bar is on
    required property string screenName

    // What is typed in the field. It lives here and not in the popup, because the popup's
    // contents are thrown away whenever it closes, and a picked color has to survive that.
    property string input: ""
    // the typed text as "#rrggbb", or "" while it is not a color
    readonly property string color: ColorPickerService.parseColor(input)

    // red, green and blue (0 to 255) of the last color the field held; the sliders show
    // these, so they stay where they were while what is typed is not a color
    property var channels: [0, 0, 0]
    onColorChanged: {
        if (color !== "")
            channels = ColorPickerService.channels(color);
    }

    // a slider was moved: set that one channel (0 to 1 along the slider) and keep the others
    function setChannel(index: int, fraction: real): void {
        const next = channels.slice();
        next[index] = Math.round(fraction * 255);
        input = ColorPickerService.fromChannels(next[0], next[1], next[2]);
    }

    implicitWidth: 26
    implicitHeight: 26

    Text {
        anchors.centerIn: parent
        text: Icons.palette
        // brighter while hovered or while the popup is open; dim while picking
        color: ColorPickerService.picking ? Theme.secondaryText
            : (popup.open || mouse.containsMouse) ? Theme.accentHover : Theme.accent
        font.family: Fonts.materialIconFontFamily
        font.pixelSize: Fonts.bodyLarge
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.toggle()
    }

    // A picked color goes into the field. Every monitor has a bar, but only the one you
    // are on opens its popup.
    Connections {
        target: ColorPickerService

        function onPicked(color: string): void {
            root.input = color;
            const focused = Hyprland.focusedMonitor;
            if (!focused || focused.name === root.screenName)
                popup.open = true;
        }
    }

    BarPopup {
        id: popup

        popupWidth: 260
        padding: 12

        ColumnLayout {
            spacing: 8

            RowLayout {
                spacing: 10

                // the color that is typed in the field
                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: 8
                    color: root.color !== "" ? root.color : Theme.surface
                    border.width: 1
                    border.color: Theme.surfaceBorder

                    Text {
                        visible: root.color === ""
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
                    border.color: input.text !== "" && root.color === "" ? Theme.danger
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
                            text: root.input
                            color: Theme.primaryText
                            font.family: Fonts.bodyFontFamily
                            font.pixelSize: Fonts.bodyMedium
                            selectByMouse: true
                            selectionColor: Theme.accent
                            selectedTextColor: Theme.accentText

                            onTextEdited: root.input = text
                            // Enter tidies the text up: "C8A96A" becomes "#c8a96a"
                            onAccepted: if (root.color !== "") root.input = root.color

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
                                    popup.close();
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
                        value: root.channels[channelRow.index] / 255
                        onMoved: fraction => root.setChannel(channelRow.index, fraction)
                    }

                    Text {
                        // a fixed width, so the slider does not change length with the number
                        Layout.preferredWidth: 26
                        horizontalAlignment: Text.AlignRight
                        text: root.channels[channelRow.index]
                        color: Theme.secondaryText
                        font.family: Fonts.bodyFontFamily
                        font.pixelSize: Fonts.labelMedium
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: input.text !== "" && root.color === ""
                    ? "That is not a hex color. Use 6 digits, like #c8a96a."
                    : "Type a hex code, move the sliders, or pick a color from the screen with the eyedropper."
                color: input.text !== "" && root.color === "" ? Theme.danger : Theme.mutedText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelSmall
            }
        }
    }
}
