import QtQuick
import "../../../singletons"

// "󰏘  Theme": a small icon followed by a title, above each group of options
Row {
    property string icon
    property string title

    spacing: 8

    Text {
        text: parent.icon
        color: Theme.accent
        font.family: Fonts.materialIconFontFamily
        font.pixelSize: Fonts.bodyLarge
    }

    Text {
        text: parent.title
        color: Theme.primaryText
        font.family: Fonts.bodyFontFamily
        font.pixelSize: Fonts.bodyMedium
        font.weight: Font.Medium
    }
}
