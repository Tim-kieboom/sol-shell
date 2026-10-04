import Quickshell
import QtQuick
import QtQuick.Layouts
import "../singletons"
import "../statusbar/components"

// The contents of the popup behind the bell: a do-not-disturb switch and the
// history of notifications, newest first.
ColumnLayout {
    id: root

    spacing: 10

    // A clock that ticks once a minute. Passing its time to the rows makes every
    // "5 min ago" update by itself while the panel is open.
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // ---------- header ----------
    RowLayout {
        Layout.fillWidth: true

        Text {
            Layout.fillWidth: true
            text: "Notifications"
            color: Theme.primaryText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.titleSmall
            font.weight: Font.Medium
        }

        Text {
            visible: NotificationService.history.length > 0
            text: "Clear all"
            color: clearMouse.containsMouse ? Theme.accentHover : Theme.accent
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.labelMedium

            MouseArea {
                id: clearMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: NotificationService.clear()
            }
        }
    }

    ConnectivityRow {
        Layout.fillWidth: true
        icon: Icons.notificationsOff
        title: "Do not disturb"
        subtitle: "No popups. Critical ones still show"
        checked: NotificationService.doNotDisturb
        onToggled: NotificationService.toggleDoNotDisturb()
    }

    // thin line between the controls and the list
    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Theme.surfaceBorder
    }

    // ---------- the history ----------
    Text {
        Layout.fillWidth: true
        Layout.topMargin: 6
        Layout.bottomMargin: 6
        visible: NotificationService.history.length === 0
        horizontalAlignment: Text.AlignHCenter
        text: "No notifications"
        color: Theme.mutedText
        font.family: Fonts.bodyFontFamily
        font.pixelSize: Fonts.bodySmall
    }

    // Up to 50 entries do not fit, so the list scrolls: as tall as its content, up
    // to 420px, then it scrolls.
    Flickable {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(list.implicitHeight, 420)
        visible: NotificationService.history.length > 0
        contentHeight: list.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: list
            width: parent.width
            spacing: 2

            Repeater {
                // objectProp says which field identifies an entry, so when an entry
                // changes (an app updated its notification) its row is updated, and
                // the other rows are left alone
                model: ScriptModel {
                    values: NotificationService.history
                    objectProp: "id"
                }

                NotificationHistoryRow {
                    required property var modelData
                    entry: modelData
                    now: clock.date
                    width: list.width
                }
            }
        }
    }
}
