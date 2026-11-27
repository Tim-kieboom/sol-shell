import QtQuick
import QtQuick.Layouts
import "../../singletons"
import "../../utils"

// One line in the popup: icon, name + status, switch. Used for wifi and bluetooth.
RowLayout {
    // this monitor's colors
    readonly property var theme: Theme.forScreen(Window.window?.screen?.name ?? "")
    id: root

    property string icon
    property string title
    property string subtitle
    property bool checked: false
    signal toggled

    spacing: 10

    Text {
        text: root.icon
        color: root.checked ? theme.accent : theme.secondaryText
        font.family: Fonts.materialIconFontFamily
        font.pixelSize: Fonts.titleMedium
    }

    // title above, status below
    Column {
        // fillWidth pushes the switch to the right edge
        Layout.fillWidth: true

        Text {
            text: root.title
            color: theme.primaryText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.bodyMedium
        }

        Text {
            text: root.subtitle
            color: theme.secondaryText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.labelSmall
            elide: Text.ElideRight
            // never let a long network name stretch the popup
            width: Math.min(implicitWidth, 150)
        }
    }

    ToggleSwitch {
        checked: root.checked
        onToggled: root.toggled()
    }
}
