pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// The on-screen display for the volume keys. It reacts only to the key commands below
// (`sol-shell ipc call osd volume-up` in a keybind), never to the volume changing some other way:
// the bar's own volume ring, a mixer or an app starting up change the volume without a popup.
//
// The command changes the volume itself, through AudioService, so the step and the 150% limit are
// the same as the ring's. Your keybinds call it instead of wpctl or pamixer.
Singleton {
    id: root

    // how much one key press changes the volume (5%)
    readonly property real step: 0.05
    // how long the popup stays after the last key press, in milliseconds
    readonly property int showFor: 1500

    // true while the popup is on screen
    property bool shown: false

    Timer {
        id: hideTimer
        interval: root.showFor
        onTriggered: root.shown = false
    }

    // Show the popup, or keep it a little longer when it is already there (a held key repeats).
    function show(): void {
        // with no output device there is nothing to show
        if (!AudioService.available)
            return;
        root.shown = true;
        hideTimer.restart();
    }

    function volumeUp(): void {
        AudioService.changeVolume(root.step);
        root.show();
    }

    function volumeDown(): void {
        AudioService.changeVolume(-root.step);
        root.show();
    }

    function toggleMute(): void {
        AudioService.toggleMute();
        root.show();
    }

    IpcHandler {
        target: "osd"

        function volumeUp(): void {
            root.volumeUp();
        }

        function volumeDown(): void {
            root.volumeDown();
        }

        function mute(): void {
            root.toggleMute();
        }
    }
}
