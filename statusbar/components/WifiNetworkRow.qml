import QtQuick
import QtQuick.Layouts
import "../../singletons"

// One wifi network in the popup. Click to connect / disconnect. For a new
// secured network, a password field slides open underneath.
//
// The root is now a Column: the clickable header on top, the password area
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
    Rectangle {
        width: root.width
        height: 38
        radius: 8
        color: (mouse.containsMouse && (root.actionable || root.prompting)) || root.prompting
            ? Theme.nonAccent : "transparent"
        // dimmed only when we can't do anything at all
        opacity: root.actionable || root.prompting ? 1.0 : 0.6

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 10

            Text {
                text: NetworkService.signalIcon(root.network)
                color: root.network.connected ? Theme.accent : Theme.secondaryText
                font.family: Fonts.materialIconFontFamily
                font.pixelSize: Fonts.titleSmall
            }

            Column {
                Layout.fillWidth: true

                Text {
                    text: root.network.name
                    color: Theme.primaryText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.bodySmall
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, 170)
                }

                Text {
                    text: NetworkService.networkStatus(root.network)
                    color: Theme.secondaryText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.labelSmall
                }
            }

            // padlock for secured networks
            Text {
                visible: NetworkService.isSecured(root.network)
                text: Icons.lock
                color: Theme.secondaryText
                font.family: Fonts.materialIconFontFamily
                font.pixelSize: Fonts.labelMedium
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: NetworkService.toggleConnection(root.network)
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
