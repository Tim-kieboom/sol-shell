pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire

// Audio for the bar, via PipeWire: volume and mute of the default output
// (speakers, headphones), the list of output devices and which one is the
// default, and the volume and mute of the default microphone.
// Volume is a fraction: 1.0 is 100%, and it can go up to 1.5.
Singleton {
    id: root

    // The highest volume we will set (150%, like the system mixer allows)
    readonly property real maxVolume: 1.5

    // ---- the default output ----

    // The sink (output device) the system currently plays through, e.g.
    // speakers or headphones. Pipewire updates this when you switch device.
    readonly property var sink: Pipewire.defaultAudioSink

    // The default input (microphone), the same idea.
    readonly property var source: Pipewire.defaultAudioSource

    // Pipewire only fills in a node's `audio` (volume, muted) for nodes that
    // something is "tracking". Without this, volume would read as 0 or null.
    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    readonly property bool available: sink !== null && sink.audio !== null
    readonly property real volume: available ? sink.audio.volume : 0
    readonly property bool muted: available ? sink.audio.muted : false

    readonly property bool micAvailable: source !== null && source.audio !== null
    readonly property real micVolume: micAvailable ? source.audio.volume : 0
    readonly property bool micMuted: micAvailable ? source.audio.muted : false

    function setVolume(value: real): void {
        if (!available)
            return;
        sink.audio.volume = Math.max(0, Math.min(maxVolume, value));
    }

    function changeVolume(delta: real): void {
        setVolume(volume + delta);
    }

    function toggleMute(): void {
        if (available)
            sink.audio.muted = !sink.audio.muted;
    }

    function setMicVolume(value: real): void {
        if (micAvailable)
            source.audio.volume = Math.max(0, Math.min(maxVolume, value));
    }

    function toggleMicMute(): void {
        if (micAvailable)
            source.audio.muted = !source.audio.muted;
    }

    // ---- output devices ----

    // Every real output device, sorted by name. Pipewire's node list also holds
    // the playback streams of apps (a browser, a music player), which have type
    // AudioSink + Stream and are left out here: only the plain AudioSink type is
    // a device you can play through.
    readonly property var sinks: Pipewire.nodes.values
        .filter(n => n.type === PwNodeType.AudioSink)
        .sort((a, b) => displayName(a).localeCompare(displayName(b)))

    function isDefaultSink(node: var): bool {
        return sink !== null && node.id === sink.id;
    }

    // Make a device the default. "preferred" is a request: PipeWire (through its
    // session manager) decides, and moves the apps that follow the default.
    function setDefaultSink(node: var): void {
        Pipewire.preferredDefaultAudioSink = node;
    }

    // The name to show for a device, e.g. "USB Audio Speakers"
    function displayName(node: var): string {
        if (!node)
            return "";
        return node.description !== "" ? node.description : node.name;
    }

    // Devices have no icon of their own, so guess from the name: anything that
    // sounds like headphones gets the headphones icon, everything else the speaker.
    function iconFor(node: var): string {
        return /headphone|headset|ath-m|buds|pods/i.test(displayName(node))
            ? Icons.headphones : Icons.speaker;
    }
}
