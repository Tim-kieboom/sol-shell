pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire

// Volume and mute of the default audio output (speakers, headphones), via
// PipeWire. Volume is a fraction: 1.0 is 100%, and it can go up to 1.5.
Singleton {
    id: root

    // The sink (output device) the system currently plays through, e.g.
    // speakers or headphones. Pipewire updates this when you switch device.
    readonly property var sink: Pipewire.defaultAudioSink

    // Pipewire only fills in a node's `audio` (volume, muted) for nodes that
    // something is "tracking". Without this, volume would read as 0 or null.
    PwObjectTracker {
        objects: [root.sink]
    }

    readonly property bool available: sink !== null && sink.audio !== null
    readonly property real volume: available ? sink.audio.volume : 0
    readonly property bool muted: available ? sink.audio.muted : false

    function setVolume(value: real): void {
        if (!available)
            return;
        // 0 to 1.5: lets you go up to 150% like the system mixer does
        sink.audio.volume = Math.max(0, Math.min(1.5, value));
    }

    function changeVolume(delta: real): void {
        setVolume(volume + delta);
    }

    function toggleMute(): void {
        if (available)
            sink.audio.muted = !sink.audio.muted;
    }
}
