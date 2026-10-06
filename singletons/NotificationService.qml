pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Receives the notifications that apps send (a browser, a chat app, notify-send),
// shows them as popups, and keeps a history of them. Apps send them over D-Bus to
// whoever owns the name org.freedesktop.Notifications; creating the server below
// is what makes this shell that owner. Only ONE program can own that name, so
// another notification daemon (mako, dunst) cannot run at the same time.
Singleton {
    id: root

    // ---------------------------------------------------------------- popups

    // seconds a popup stays when the app does not say (it sends -1 for "you
    // decide"), per urgency
    readonly property real defaultSecondsNormal: 6
    readonly property real defaultSecondsLow: 4

    // The notifications that are showing as popups right now, oldest first. A
    // notification leaves this list when it expires, is dismissed, or the app
    // withdraws it. Each entry is a live Notification object.
    readonly property var notifications: server.trackedNotifications

    // Newest first, which is the order the popups are stacked in. The shell's own
    // messages (ShellMessages) go on top of the apps' notifications; a card cannot
    // tell the two apart.
    readonly property var newestFirst: [...ShellMessages.active].reverse()
        .concat([...server.trackedNotifications.values].reverse())

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
    // can give a path, a file:// or image:// URL, or just the NAME of an icon in the
    // icon theme, and an image they attach themselves wins over the app's icon.
    // Other URLs (http, https, ...) are refused: any program on the machine can send a
    // notification, and the shell must not fetch from the internet because it says so.
    function iconSource(notification: var): string {
        const source = notification.image || notification.appIcon;
        if (!source)
            return "";
        if (source.startsWith("/"))
            return Settings.fileUrl(source);
        if (source.startsWith("file://") || source.startsWith("image://"))
            return source;
        if (source.includes(":"))
            return "";
        return Quickshell.iconPath(source, true);
    }

    // ---------------------------------------------------------- do not disturb

    // While on, notifications do not pop up (critical ones still do). They are
    // still recorded in the history, so nothing is lost. Saved between restarts.
    readonly property bool doNotDisturb: Settings.doNotDisturb

    function toggleDoNotDisturb(): void {
        Settings.doNotDisturb = !Settings.doNotDisturb;
    }

    // ---------------------------------------------------------------- history

    // The most entries kept; older ones are dropped
    readonly property int maxHistory: 50

    // Everything received, newest first. A popup's Notification object is gone
    // once it expires, so each entry is a plain COPY of what we need to show it
    // later: { id, appName, summary, body, picture, urgency, isError, time, read }.
    // The array is replaced as a whole on every change (never edited in place),
    // which is what lets the lists that show it notice the change.
    property var history: []

    readonly property int unreadCount: history.filter(entry => !entry.read).length

    // How many notification centers (the popup behind the bell) are open. There is
    // one per monitor, so this is a count and not a flag, like NetworkService's
    // viewerCount. While any is open, what arrives counts as read: you can see it.
    property int centerViewers: 0
    readonly property bool centerOpen: centerViewers > 0
    onCenterViewersChanged: {
        if (centerOpen)
            markAllRead();
    }

    // Add a notification to the history. If an entry with the same id exists (the
    // app updated its notification), that one is replaced and moves to the top.
    function record(notification: var): void {
        const entry = {
            id: notification.id,
            appName: notification.appName,
            summary: notification.summary,
            body: notification.body,
            picture: iconSource(notification),
            urgency: notification.urgency,
            isError: notification.isError === true,
            time: new Date(),
            read: centerOpen
        };
        const others = history.filter(old => old.id !== entry.id);
        history = [entry, ...others].slice(0, maxHistory);
    }

    function remove(id: int): void {
        history = history.filter(entry => entry.id !== id);
    }

    function clear(): void {
        history = [];
    }

    function markAllRead(): void {
        if (unreadCount > 0)
            history = history.map(entry => entry.read ? entry : Object.assign({}, entry, { read: true }));
    }

    // "just now", "5 min ago", "3 h ago", or the date for anything older. `now`
    // is passed in (not read here) so that a list showing this can pass a clock
    // that ticks, and the text updates by itself.
    function relativeTime(time: date, now: date): string {
        const minutes = Math.floor((now - time) / 60000);
        if (minutes < 1)
            return "just now";
        if (minutes < 60)
            return minutes + " min ago";
        if (minutes < 24 * 60)
            return Math.floor(minutes / 60) + " h ago";
        return Qt.formatDateTime(time, "d MMM");
    }

    // -------------------------------------------------------------- the server

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
        // as tracked, which is what puts it in trackedNotifications (and so on screen).
        onNotification: notification => {
            root.record(notification);

            // The app can withdraw a notification that became obsolete (a "downloading"
            // message once the download is done). Then it should leave the history
            // too. Our own closing (it expired, you dismissed it) keeps the entry.
            notification.closed.connect(reason => {
                if (reason === NotificationCloseReason.CloseRequested)
                    root.remove(notification.id);
            });
            // An app can also update a notification it already sent; keep the
            // history entry in step.
            notification.summaryChanged.connect(() => root.record(notification));
            notification.bodyChanged.connect(() => root.record(notification));

            notification.tracked = true;
            // Do not disturb: it is recorded above, but must not pop up. Expiring it
            // right away takes it off the popup list again.
            if (root.doNotDisturb && notification.urgency !== NotificationUrgency.Critical)
                notification.expire();
        }
    }

    // ------------------------------------------------------------- ipc control

    // Lets you control this from outside the shell, for example from a Hyprland
    // keybind:   sol-shell ipc call notifications toggleDoNotDisturb
    IpcHandler {
        target: "notifications"

        function toggleDoNotDisturb(): void {
            root.toggleDoNotDisturb();
        }

        function clear(): void {
            root.clear();
        }

        function unread(): int {
            return root.unreadCount;
        }

        function count(): int {
            return root.history.length;
        }

        // one line per entry, newest first: id, urgency (0 low, 1 normal, 2 critical),
        // read or unread, and the title
        function list(): string {
            return root.history.map(e => e.id + " u" + e.urgency + " " + (e.read ? "read  " : "unread") + " " + e.summary).join("\n");
        }

        function dnd(): bool {
            return root.doNotDisturb;
        }
    }
}
