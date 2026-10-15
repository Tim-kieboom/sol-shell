pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

// Whether a program is listening to your microphone, looking at your camera or recording your screen
// right now, and which. It reads PipeWire, the sound and video server: everything that moves between
// programs there is a link from a source to a program that takes it. So a link that is carrying data
// (`Active`) says what is going on by where it starts:
//
//   an audio source (a microphone)             a program is listening to it
//   a video source (a camera)                  a program is looking at it
//   a video stream (what a screen cast makes)  a program is recording or sharing the screen
//
// It looks at the source, not at the program: what a program says about itself (its media class) is
// often missing or wrong, what a camera or a microphone is is not.
//
// Not counted: streams PipeWire makes for itself (their class says `Internal`, like the one a
// Bluetooth headset keeps), and a program listening to what is playing (that starts at a speaker,
// not a microphone). A program that has a stream open but is not receiving anything (its link is
// paused) does not count either.
//
//     sol-shell ipc call privacy status       for example "microphone: Discord; camera: -; screen: -"
Singleton {
    id: root

    // Every link between two nodes, and the nodes themselves, have to be tracked before PipeWire tells
    // us anything about them: a link says it is `Error` and a node has no properties until then. So
    // all of them are tracked, not only the ones that turn out to carry data.
    readonly property var groups: Pipewire.linkGroups.values

    // both ends of every link, and the links (a plain loop: this JavaScript has no flatMap)
    readonly property var tracked: {
        const objects = [];
        for (const group of groups) {
            objects.push(group);
            if (group.source)
                objects.push(group.source);
            if (group.target)
                objects.push(group.target);
        }
        return objects;
    }

    PwObjectTracker {
        objects: root.tracked
    }

    // the links that are carrying data
    readonly property var activeLinks: groups.filter(g => g.state === PwLinkState.Active && g.source && g.target)

    // What one link means: { kind: "microphone" | "camera" | "screen", app: "Discord" }, or null.
    function describe(link: var): var {
        const from = link.source.properties ?? {};
        const to = link.target.properties ?? {};
        const sourceClass = from["media.class"] ?? "";
        const targetClass = to["media.class"] ?? "";
        // PipeWire's own streams
        if (targetClass.includes("Internal"))
            return null;
        let kind = null;
        if (sourceClass.startsWith("Audio/Source"))
            kind = "microphone";
        else if (sourceClass.startsWith("Video/Source"))
            kind = "camera";
        else if (sourceClass.startsWith("Stream/Output/Video"))
            kind = "screen";
        if (kind === null)
            return null;
        const app = to["application.name"] || to["application.process.binary"] || to["node.description"] || link.target.description || link.target.name || "A program";
        return {
            kind: kind,
            app: app
        };
    }

    // the programs using each, once each, in order
    function appsOf(kind: string): var {
        const apps = [];
        for (const link of activeLinks) {
            const what = describe(link);
            if (what && what.kind === kind && !apps.includes(what.app))
                apps.push(what.app);
        }
        return apps.sort();
    }

    readonly property var microphone: appsOf("microphone")
    readonly property var camera: appsOf("camera")
    readonly property var screen: appsOf("screen")

    readonly property bool anyActive: microphone.length > 0 || camera.length > 0 || screen.length > 0

    // the same in one line, for a terminal
    readonly property string summary: "microphone: " + (microphone.join(", ") || "-") + "; camera: " + (camera.join(", ") || "-") + "; screen: " + (screen.join(", ") || "-")

    IpcHandler {
        target: "privacy"

        function status(): string {
            return root.summary;
        }
    }
}
