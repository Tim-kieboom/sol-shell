import QtQuick
import QtQuick.Layouts
import "../../singletons"

// One wifi network in the popup. Click to connect / disconnect. For a new
// secured network, a password field slides open underneath.
//
// The root is a Column: the clickable header (a ListRow) on top, the password area
// below it. The Column grows by itself when the password area becomes visible.
Column {
    id: root

    // The network object, handed in by whoever creates the row
    required property var network

    readonly property bool prompting: NetworkService.pendingNetwork === root.network
    // rows we can't act on yet (new secured networks) look slightly dimmer
    readonly property bool actionable: root.network.connected || !NetworkService.needsPassword(root.network)

    spacing: 4

    // when the prompt closes (cancelled, submitted, switched to another row), forget the text
    onPromptingChanged: {
        if (!prompting) {
            passwordInput.text = "";
            showPassword = false;
        }
    }
    property bool showPassword: false

    // ---------- header: the clickable network line ----------
    ListRow {
        width: root.width

        icon: NetworkService.signalIcon(root.network)
        iconColor: root.network.connected ? Theme.accent : Theme.secondaryText
        title: root.network.name
        subtitle: NetworkService.networkStatus(root.network)

        // Keep the highlight on while the password box is open under this row.
        // Rows we can't act on yet (new secured networks) don't react to hovering
        // and look slightly dimmer, unless their password box is open.
        highlighted: root.prompting
        hoverHighlight: root.actionable || root.prompting
        opacity: root.actionable || root.prompting ? 1.0 : 0.6

        onClicked: NetworkService.toggleConnection(root.network)

        // padlock for secured networks (goes into the row's right-hand side)
        Text {
            visible: NetworkService.isSecured(root.network)
            text: Icons.lock
            color: Theme.secondaryText
            font.family: Fonts.materialIconFontFamily
            font.pixelSize: Fonts.labelMedium
        }
    }

    // ---------- password area: only exists while this row is prompting ----------
    Rectangle {
        visible: root.prompting
        width: root.width
        height: visible ? 36 : 0
        radius: 8
        color: Theme.shellBackground
        border.color: passwordInput.activeFocus ? Theme.accent : Theme.surfaceBorder
        border.width: 1

        // Give the text field the keyboard as soon as this box appears, so the
        // user can type immediately. (Asking while still invisible can fail.)
        onVisibleChanged: if (visible) passwordInput.forceActiveFocus()

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 6
            spacing: 6

            // TextInput is the bare typing area; it has no look of its own,
            // so we draw the box (above) and the placeholder (below) ourselves.
            TextInput {
                id: passwordInput
                Layout.fillWidth: true
                clip: true
                color: Theme.primaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.bodySmall
                selectionColor: Theme.accent
                selectedTextColor: Theme.accentText
                // dots instead of letters, unless the eye button was pressed
                echoMode: root.showPassword ? TextInput.Normal : TextInput.Password

                // Enter submits, Escape cancels
                onAccepted: NetworkService.submitPassword(text)
                Keys.onEscapePressed: NetworkService.cancelPassword()

                // placeholder: shown only while the field is empty
                Text {
                    visible: passwordInput.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Password"
                    color: Theme.mutedText
                    font: passwordInput.font
                }
            }

            // show / hide password
            Text {
                text: root.showPassword ? Icons.passwordVisible : Icons.passwordHidden
                color: Theme.secondaryText
                font.family: Fonts.materialIconFontFamily
                font.pixelSize: Fonts.bodyMedium

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.showPassword = !root.showPassword
                }
            }

            // connect button; greyed out until something is typed
            Text {
                text: Icons.confirm
                color: passwordInput.text !== "" ? Theme.accent : Theme.mutedText
                font.family: Fonts.materialIconFontFamily
                font.pixelSize: Fonts.bodyLarge

                MouseArea {
                    anchors.fill: parent
                    enabled: passwordInput.text !== ""
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NetworkService.submitPassword(passwordInput.text)
                }
            }
        }
    }
}
