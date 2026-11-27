import QtQuick
import "../../../singletons"

// The weather in the bar: an icon for the conditions and the temperature, like
// "󰖕 14°". It stays hidden until there is weather to show, so without a location
// file the bar just has no weather. The data comes from WeatherService.
Row {
    // this monitor's colors
    readonly property var theme: Theme.forScreen(Window.window?.screen?.name ?? "")
    id: root

    visible: WeatherService.configured && WeatherService.available
    spacing: 5

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: WeatherService.icon
        // a dimmed icon when the last refresh failed and the number may be old
        color: WeatherService.stale ? theme.mutedText : theme.accent
        font.family: Fonts.materialIconFontFamily
        font.pixelSize: Fonts.bodyLarge
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: WeatherService.degrees(WeatherService.temperature)
        color: theme.secondaryText
        font.family: Fonts.bodyFontFamily
        font.pixelSize: Fonts.bodyMedium
        font.weight: Font.Light
    }
}
