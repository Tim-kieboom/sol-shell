pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Whether there is an update for NixOS, for the update item of the bar. Two things are checked:
//
//   a newer nixpkgs   The nixpkgs your system was built from is compared with the newest commit of
//                     the branch it follows (`nixos-26.05`, say), which is what a `nix flake update`
//                     would fetch now. The branch comes from the `nixpkgs` input of
//                     /etc/nixos/flake.lock (a GitHub input); what is running is what
//                     `nixos-version` reports. Asking GitHub is one `git ls-remote`, which sends
//                     nothing but the question.
//   a restart         The kernel (or its modules, or the initrd) of the system that is running is not
//                     the one of the newest generation: it was rebuilt, but the old kernel runs on.
//
// This only tells you; it never rebuilds anything. It checks a little after the shell starts, then
// every six hours, and when asked.
//
//     sol-shell ipc call updates status       for example "update: 6fcc160 -> a033e66 (nixos-26.05); restart: no"
//     sol-shell ipc call updates check
Singleton {
    id: root

    // where flake.lock is (a NixOS configuration as a flake, the usual place)
    readonly property string lockPath: "/etc/nixos/flake.lock"

    property bool checking: false
    // true once a check has ended (with an answer or with a failure)
    property bool checked: false
    // when the last check ended
    property var checkedAt: null
    // what went wrong with the last check ("" when nothing did)
    property string failure: ""

    // the branch being followed, as the lock names it ("nixos-26.05"), and the two commits
    property string branch: ""
    property string runningRevision: ""
    property string remoteRevision: ""
    property bool restartNeeded: false

    readonly property bool updateAvailable: runningRevision !== "" && remoteRevision !== "" && runningRevision !== remoteRevision
    // whether the bar has anything to show
    readonly property bool anyActive: updateAvailable || restartNeeded

    // "6fcc160" from a full commit id
    function shortRevision(revision: string): string {
        return revision.slice(0, 7);
    }

    readonly property string status: "update: " + (updateAvailable ? shortRevision(runningRevision) + " -> " + shortRevision(remoteRevision) + " (" + branch + ")" : (failure !== "" ? "unknown (" + failure + ")" : "none")) + "; restart: " + (restartNeeded ? "yes" : "no")

    function check(): void {
        if (checking)
            return;
        checking = true;
        failure = "";
        lockFile.reload();
    }

    function finish(message: string): void {
        failure = message;
        checking = false;
        checked = true;
        checkedAt = new Date();
    }

    // The place to ask, from the lock: the `nixpkgs` input of the flake, followed through "follows"
    // lists, and the branch it was written with.
    function parseLock(contents: string): void {
        let lock;
        try {
            lock = JSON.parse(contents);
        } catch (e) {
            finish("flake.lock is not readable");
            return;
        }
        let node = lock.nodes?.[lock.root]?.inputs?.nixpkgs;
        if (Array.isArray(node)) {
            let target = lock.root;
            for (const step of node)
                target = lock.nodes?.[target]?.inputs?.[step];
            node = target;
        }
        const original = lock.nodes?.[node]?.original;
        if (!original || original.type !== "github") {
            finish("nixpkgs is not a GitHub input");
            return;
        }
        branch = original.ref ?? "HEAD";
        const ref = original.ref ? "refs/heads/" + original.ref : "HEAD";
        ask.command = ["sh", "-c", script, "sh", "https://github.com/" + original.owner + "/" + original.repo, ref];
        ask.running = true;
    }

    // One program for all three questions; each prints one line that parse() recognises.
    readonly property string script: [
        // what is running (a JSON line)
        "nixos-version --json 2>/dev/null",
        // the newest commit of the branch (a 40-letter id, a tab, the name)
        "GIT_TERMINAL_PROMPT=0 timeout 30 git ls-remote \"$1\" \"$2\" 2>/dev/null | head -n 1 | cut -f 1 | sed 's/^/remote=/'",
        // is the kernel that runs the one of the newest generation
        "for part in kernel kernel-modules initrd; do [ \"$(readlink -f /run/booted-system/$part 2>/dev/null)\" = \"$(readlink -f /run/current-system/$part 2>/dev/null)\" ] || { echo restart=yes; exit 0; }; done; echo restart=no"
    ].join("\n")

    function parse(contents: string): void {
        let running = "";
        let remote = "";
        let restart = false;
        for (const line of contents.split("\n")) {
            if (line.startsWith("{")) {
                try {
                    running = JSON.parse(line).nixpkgsRevision ?? "";
                } catch (e) {}
            } else if (line.startsWith("remote=")) {
                remote = line.slice(7).trim();
            } else if (line === "restart=yes") {
                restart = true;
            }
        }
        runningRevision = running;
        remoteRevision = remote;
        restartNeeded = restart;
        if (running === "")
            finish("the running nixpkgs is unknown");
        else if (remote === "")
            finish("GitHub did not answer");
        else
            finish("");
    }

    FileView {
        id: lockFile
        path: root.lockPath
        printErrors: false
        onLoaded: root.parseLock(text())
        onLoadFailed: root.finish("no " + root.lockPath)
    }

    Process {
        id: ask
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    // a little after the shell starts (so it does not compete with it), then every six hours
    Timer {
        interval: 20000
        running: true
        onTriggered: root.check()
    }

    Timer {
        interval: 6 * 3600 * 1000
        repeat: true
        running: true
        onTriggered: root.check()
    }

    IpcHandler {
        target: "updates"

        function status(): string {
            return root.status;
        }

        function check(): void {
            root.check();
        }
    }
}
