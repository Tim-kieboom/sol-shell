pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick

// What is playing: picks one media player (Spotify, a browser, mpv, ...) from
// MPRIS and exposes its track, state and controls to the bar.
Singleton {
    id: root

    // The player the user picked by hand (its D-Bus name). Empty = no choice
    // made, so the automatic pick below is used. Not readonly: the UI changes it
    // through selectRelative().
    property string selectedPlayerName: ""

    // Mpris.players is a live list of every media player on D-Bus
    // (Spotify, Firefox, mpv, ...). `.values` turns it into a plain JS array.
    // Ignore players with nothing to show (e.g. an idle browser that reports
    // "Stopped" and no title).
    readonly property var players: Mpris.players.values.filter(p => p.trackTitle !== "")
    readonly property int playerCount: players.length

    // Priority: 1) the one the user picked, 2) one that is playing right now,
    // 3) the first one (a paused player keeps its track). If the picked player
    // closes, step 1 finds nothing and we silently fall through to 2 and 3.
    readonly property var currentPlayer:
        players.find(p => p.dbusName === selectedPlayerName)
        ?? players.find(p => p.isPlaying)
        ?? players[0]
        ?? null

    // 0-based position of the current player in the list, -1 if there is none
    readonly property int currentIndex:
        players.findIndex(p => p.dbusName === currentPlayer?.dbusName)

    readonly property bool available: currentPlayer !== null && title !== ""
    readonly property string title: currentPlayer ? currentPlayer.trackTitle : ""
    readonly property string artist: currentPlayer ? currentPlayer.trackArtist : ""
    readonly property bool playing: currentPlayer ? currentPlayer.isPlaying : false
    readonly property bool canTogglePlaying: currentPlayer ? currentPlayer.canTogglePlaying : false
    readonly property bool canGoPrevious: currentPlayer ? currentPlayer.canGoPrevious : false
    readonly property bool canGoNext: currentPlayer ? currentPlayer.canGoNext : false
    // Seeking needs both: the player must allow it AND know how long the track is
    readonly property bool canSeek: currentPlayer ? currentPlayer.canSeek && durationSeconds > 0 : false
    readonly property real positionSeconds: currentPlayer ? currentPlayer.position : 0
    readonly property real durationSeconds: currentPlayer ? currentPlayer.length : 0

    // 0.0 - 1.0, same scale as SystemStats.cpuUsage. Guarded because length
    // can be 0 (live streams) and we must not divide by zero.
    readonly property real progress: durationSeconds > 0
        ? Math.min(1, Math.max(0, positionSeconds / durationSeconds))
        : 0

    // A player only announces "the position jumped" (seek, new track). While a
    // song just plays on, nothing is announced, so `position` goes stale. This
    // timer pokes the property once a second so bindings re-read it. It only
    // runs while playing, so a paused player costs nothing.
    Timer {
        interval: 1000
        running: root.playing
        repeat: true
        onTriggered: root.currentPlayer.positionChanged()
    }

    // ---- actions ----
    // Properties describe state; functions do things. The UI never touches the
    // player directly, it only calls these, so all the safety checks live here.

    // Switch to another player by hand. offset +1 = next, -1 = previous;
    // wraps around at both ends.
    function selectRelative(offset: int): void {
        if (playerCount < 2)
            return;
        const index = Math.max(0, currentIndex);
        const target = (index + offset + playerCount) % playerCount;
        selectedPlayerName = players[target].dbusName;
    }

    // fraction is 0..1 (0 = start of the song). The UI only knows "I clicked 40%
    // of the way along the bar"; turning that into seconds is the service's job.
    function seekToFraction(fraction: real): void {
        if (!canSeek)
            return;
        const clamped = Math.max(0, Math.min(1, fraction));
        // position is writable on the player: assigning it asks the player to jump
        currentPlayer.position = clamped * durationSeconds;
    }

    function playPause(): void {
        if (currentPlayer && currentPlayer.canTogglePlaying)
            currentPlayer.togglePlaying();
    }

    function previous(): void {
        if (currentPlayer && currentPlayer.canGoPrevious)
            currentPlayer.previous();
    }

    function next(): void {
        if (currentPlayer && currentPlayer.canGoNext)
            currentPlayer.next();
    }
}
