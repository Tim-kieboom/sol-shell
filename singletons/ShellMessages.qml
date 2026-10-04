pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import Quickshell.Services.Notifications

// The shell's own messages: "Wrong password for ...", "Could not connect to ...".
// They are shown as cards in the same stack as the notifications that apps send,
// and are kept in the same history, but they are made here: apps have nothing to
// do with them. Unlike app notifications they ignore do not disturb, because they
// are the answer to something you just did.
//
//     ShellMessages.error("Wi-Fi", "Wrong password", "The password for Home was not accepted.")
//     ShellMessages.info("Bluetooth", "Connected", "Headphones")
//
// How it plugs in: the cards only read a few properties of a notification
// (appName, summary, body, urgency, ...) and call dismiss() or expire(). A
// ShellMessage below has the same ones, so NotificationService can put these in
// the same list as the real notifications, and the cards cannot tell the difference.
Singleton {
    id: root

    // The messages on screen right now, oldest first
    property var active: []

    // Messages get negative ids, so they can never clash with the ids that the
    // notification server gives to apps (those count up from 1).
    property int lastId: 0

    // How long an error stays, in milliseconds. Longer than a normal notification
    // because it usually has something to tell you.
    readonly property int errorMillis: 8000

    component ShellMessage: QtObject {
        id: message

        property int id: 0
        property string appName: ""
        property string summary: ""
        property string body: ""
        // same numbers as NotificationUrgency: 0 low, 1 normal, 2 critical
        property int urgency: NotificationUrgency.Normal
        // milliseconds; -1 lets NotificationService pick its default
        property int expireTimeout: -1
        // no picture of its own, so the card draws its generic icon
        property string image: ""
        property string appIcon: ""
        // what makes the card red and gives it a warning sign
        property bool isError: false
        // two messages with the same key are the same message (see post())
        property string key: ""

        signal closed(int reason)

        // the cards call these when you click one, or when its time is up
        function dismiss(): void {
            root.remove(message);
        }

        function expire(): void {
            root.remove(message);
        }
    }

    Component {
        id: messageFactory
        ShellMessage {}
    }

    // Show a message. `key` stops a failure that repeats (NetworkManager retrying a
    // network that is down) from stacking up: while a message with that key is still
    // on screen, a new one with the same key is ignored.
    function post(isError: bool, source: string, summary: string, body: string, key: string): void {
        if (key !== "" && active.some(m => m.key === key))
            return;

        lastId -= 1;
        const message = messageFactory.createObject(root, {
            id: lastId,
            appName: source,
            summary: summary,
            body: body,
            isError: isError,
            key: key,
            expireTimeout: isError ? errorMillis : -1
        });
        active = [...active, message];
        // keep it in the history too
        NotificationService.record(message);
    }

    function error(source: string, summary: string, body: string, key: string): void {
        post(true, source, summary, body, key ?? "");
    }

    function info(source: string, summary: string, body: string, key: string): void {
        post(false, source, summary, body, key ?? "");
    }

    function remove(message: var): void {
        active = active.filter(m => m !== message);
        message.closed(0);
        // The object is deleted a moment later, not now: the card showing it is still
        // reading its properties while it disappears.
        message.destroy(1000);
    }

    // ------------------------------------------------------------- ipc control

    // Lets scripts (and you, from a terminal) show a message in the shell:
    //   qs ipc -p ~/.config/quickshell/sol-shell call messages error "Backup failed" "The disk is full"
    IpcHandler {
        target: "messages"

        function error(summary: string, body: string): void {
            root.error("sol-shell", summary, body, "");
        }

        function info(summary: string, body: string): void {
            root.info("sol-shell", summary, body, "");
        }

        // how many are on screen right now
        function count(): int {
            return root.active.length;
        }
    }
}
