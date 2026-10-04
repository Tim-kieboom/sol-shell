import QtQuick
import "../../singletons"
import "../../notifications"

// A bell in the bar. A badge shows how many notifications you have not seen yet.
// Click it to open the history; middle-click toggles do not disturb (then the bell
// is crossed out and grey).
Item {
    id: root

    implicitWidth: 26
    implicitHeight: 26

    // If this bar disappears while its panel is open (a monitor is unplugged), the
    // panel's close never fires, so give back its +1 here (see below).
    Component.onDestruction: {
        if (popup.open)
            NotificationService.centerViewers -= 1;
    }

    Text {
        anchors.centerIn: parent
        text: NotificationService.doNotDisturb ? Icons.notificationsOff : Icons.notifications
        color: NotificationService.doNotDisturb ? Theme.mutedText
            : (popup.open || mouse.containsMouse) ? Theme.accentHover : Theme.accent
        font.family: Fonts.materialIconFontFamily
        font.pixelSize: Fonts.bodyLarge
    }

    // the unread count, a small round badge on the bell's top right corner
    Rectangle {
        visible: NotificationService.unreadCount > 0
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 1
        width: Math.max(height, badgeText.implicitWidth + 6)
        height: 13
        radius: height / 2
        color: Theme.accent

        Text {
            id: badgeText
            anchors.centerIn: parent
            // "9+" so the badge never grows wide
            text: NotificationService.unreadCount > 9 ? "9+" : NotificationService.unreadCount
            color: Theme.accentText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.labelTiny
            font.weight: Font.Medium
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: event => {
            if (event.button === Qt.MiddleButton)
                NotificationService.toggleDoNotDisturb();
            else
                popup.toggle();
        }
    }

    BarPopup {
        id: popup

        // this is at the right end of the bar: grow leftwards
        alignRight: true
        popupWidth: 380

        // Tell NotificationService how many panels are open: while one is open,
        // what arrives counts as read. Fires once per open and once per close.
        onOpenChanged: NotificationService.centerViewers += open ? 1 : -1

        NotificationCenter {}
    }
}
