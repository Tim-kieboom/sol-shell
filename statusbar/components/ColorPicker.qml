import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "../../singletons"

// The palette button in the bar. Click it for a small popup with a hex field: type a code
// (#c8a96a, c8a96a or #ca6) and the swatch beside it shows the color. The eyedropper in
// the field picks a color from anywhere on the screen instead, and the result is filled
// in on the same field. The picker can also be started from a keybind
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

        popupWidth: 250
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

            Text {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: input.text !== "" && root.color === ""
                    ? "That is not a hex color. Use 6 digits, like #c8a96a."
                    : "Type a hex code, or pick a color from the screen with the eyedropper."
                color: input.text !== "" && root.color === "" ? Theme.danger : Theme.mutedText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelSmall
            }
        }
    }
}
