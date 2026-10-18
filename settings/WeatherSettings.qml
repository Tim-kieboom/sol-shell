import QtQuick
import QtQuick.Layouts
import "../singletons"
import "../statusbar/components"

// The weather settings: the place (looked up by name, and written to weather-location.json) and
// Celsius or Fahrenheit. The weather in the bar and its popup follow at once, because the shell
// watches that file.
ColumnLayout {
    id: root

    spacing: 8

    // where the shell looks for the place: shown so it is clear what these settings change
    Text {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: WeatherService.configured ? WeatherService.locationName + "  (" + WeatherService.latitude.toFixed(2) + ", " + WeatherService.longitude.toFixed(2) + ")" : "No place set yet"
        color: WeatherService.configured ? Theme.primaryText : Theme.mutedText
        font.family: Fonts.bodyFontFamily
        font.pixelSize: Fonts.bodyMedium
    }

    // the search field
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 32
        radius: 8
        color: Theme.shellBackground
        border.width: 1
        border.color: input.activeFocus ? Theme.accent : Theme.surfaceBorder

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 6

            Text {
                text: Icons.search
                color: Theme.secondaryText
                font.family: Fonts.materialIconFontFamily
                font.pixelSize: Fonts.bodyLarge
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                TextInput {
                    id: input
                    anchors.fill: parent
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.primaryText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.bodyMedium
                    selectByMouse: true
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.accentText
                    clip: true
                    // a moment after the last key, not at every key
                    onTextChanged: lookup.restart()
                    // Enter looks it up at once
                    onAccepted: {
                        lookup.stop();
                        WeatherService.search(text);
                    }
                }

                // what the field is for, while it is empty
                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    visible: input.text === "" && !input.activeFocus
                    text: "Search for a city"
                    color: Theme.mutedText
                    font: input.font
                }
            }
        }

        Timer {
            id: lookup
            interval: 450
            onTriggered: WeatherService.search(input.text)
        }
    }

    Text {
        Layout.fillWidth: true
        visible: WeatherService.searching || WeatherService.searchError !== ""
        text: WeatherService.searching ? "Searching..." : WeatherService.searchError
        color: Theme.mutedText
        font.family: Fonts.bodyFontFamily
        font.pixelSize: Fonts.labelSmall
    }

    // what was found: a click chooses it
    Repeater {
        model: WeatherService.results

        ListRow {
            required property var modelData

            Layout.fillWidth: true
            icon: Icons.place
            title: modelData.name
            subtitle: modelData.detail
            onClicked: {
                WeatherService.setLocation(modelData.name, modelData.latitude, modelData.longitude);
                // done: the field and the list are cleared
                input.text = "";
                WeatherService.search("");
            }
        }
    }

    // Celsius or Fahrenheit
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: "Temperature"
            color: Theme.secondaryText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.labelMedium
        }

        Repeater {
            model: [
                {
                    id: "celsius",
                    label: "°C"
                },
                {
                    id: "fahrenheit",
                    label: "°F"
                }
            ]

            Rectangle {
                id: chip

                required property var modelData
                readonly property bool selected: (modelData.id === "fahrenheit") === WeatherService.fahrenheit

                implicitWidth: 44
                implicitHeight: 28
                radius: height / 2
                color: selected ? Theme.surface : "transparent"
                border.width: selected ? 2 : 1
                border.color: selected ? Theme.accent : Theme.surfaceBorder
                // the unit is kept in the same file as the place, so it needs one
                opacity: WeatherService.configured ? 1.0 : 0.5

                Text {
                    anchors.centerIn: parent
                    text: chip.modelData.label
                    color: chip.selected ? Theme.primaryText : Theme.mutedText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.labelMedium
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: WeatherService.configured
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WeatherService.setUnit(chip.modelData.id)
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: "The place is saved to ~/.config/quickshell/weather-location.json. Only the name you type is sent, to Open-Meteo's search; the weather then asks for the coordinates."
        color: Theme.mutedText
        font.family: Fonts.bodyFontFamily
        font.pixelSize: Fonts.labelSmall
    }
}
