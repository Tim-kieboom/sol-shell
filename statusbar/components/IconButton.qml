import QtQuick
import "../../singletons"

// A reusable icon button. The "arguments" are the properties and the signal
// below; whoever uses it fills those in.
Text {
    // this monitor's colors
    readonly property var theme: Theme.forScreen(Window.window?.screen?.name ?? "")
    id: root

    signal clicked()   // emitted on click; the user of this button decides what happens

    // `enabled` already exists on every Item. When it is false, MouseAreas
    // inside stop receiving clicks, so we only need to restyle the icon.
    color: enabled ? theme.accent : theme.secondaryText
    opacity: enabled ? 1.0 : 0.5
    font.family: Fonts.materialIconFontFamily
    font.pixelSize: Fonts.bodyLarge

    MouseArea {
        anchors.fill: parent
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
