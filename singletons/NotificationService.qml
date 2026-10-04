pragma Singleton

import Quickshell
import Quickshell.Services.Notifications

// Receives the notifications that apps send (a browser, a chat app, notify-send)
// and keeps the ones that are still showing. Apps send them over D-Bus to
// whoever owns the name org.freedesktop.Notifications; creating the server below
// is what makes this shell that owner. Only ONE program can own that name, so
// another notification daemon (mako, dunst) cannot run at the same time.
Singleton {
    id: root

    // seconds a popup stays when the app does not say (it sends -1 for "you
    // decide"), per urgency
    readonly property real defaultSecondsNormal: 6
    readonly property real defaultSecondsLow: 4

    // The notifications that are alive right now, oldest first. A notification
    // leaves this list when it expires, is dismissed, or the app withdraws it.
    // Each entry is a Notification object (summary, body, appName, urgency, ...).
    readonly property var notifications: server.trackedNotifications

    // Newest first, which is the order the popups are stacked in
    readonly property var newestFirst: [...server.trackedNotifications.values].reverse()

    // How long a popup stays on screen, in seconds; 0 means until it is dismissed.
    function popupSeconds(notification: var): real {
        // critical notifications ("battery empty", "disk full") stay until read
        if (notification.urgency === NotificationUrgency.Critical)
            return 0;
        // the app asked for a specific time. Note the unit: Quickshell reports
        // expireTimeout in MILLISECONDS (measured: a request for 2500 gives 2500),
        // and the spec says 0 means "never expire".
        if (notification.expireTimeout >= 0)
            return notification.expireTimeout / 1000;
        // -1: the app leaves it to us
        return notification.urgency === NotificationUrgency.Low
            ? defaultSecondsLow : defaultSecondsNormal;
    }

    // The picture to show, as something an Image can load, or "" for none. Apps
    // can give a path, a URL, or just the NAME of an icon in the icon theme, and
    // an image they attach themselves wins over the app's icon.
    function iconSource(notification: var): string {
        const source = notification.image || notification.appIcon;
        if (!source)
            return "";
        if (source.startsWith("/"))
            return "file://" + source;
        // already a URL (file://, image://...)
        if (source.includes(":"))
            return source;
        return Quickshell.iconPath(source, true);
    }

    NotificationServer {
        id: server

        // What we tell apps we can show. Apps adapt to this: if we said we
        // support markup, they would send <b>bold</b> text that we would show
        // as literal tags, so we say we do not.
        bodySupported: true
        bodyMarkupSupported: false
        imageSupported: true
        // Not yet: apps would add buttons that we do not draw.
        actionsSupported: false
        // We do not store notifications across restarts of the shell
        persistenceSupported: false
        // ...but a reload of the shell (saving a file) keeps the current ones
        keepOnReload: true

        // A new notification arrives. Quickshell forgets it again unless we mark it
        // as tracked, which is what puts it in trackedNotifications.
        onNotification: notification => {
            notification.tracked = true;
        }
    }
}
