pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import QtQuick

// The login: who can log in, which session to start, and the conversation with greetd
// (the login daemon that runs this greeter).
//
// greetd's side of it: createSession(user) starts a login, greetd asks for the password
// (authMessage), respond() answers, greetd says readyToLaunch, and launch() starts the
// session and ends this program. A wrong password ends that login (authFailure) and the
// next try starts a new one.
Singleton {
    id: root

    // ------------------------------------------------------------------ users

    // [{ name: "alice", display: "Alice Example" }, ...]: the people, not the system accounts
    property var users: []
    property int userIndex: 0
    readonly property string user: users.length > 0 ? users[userIndex].name : ""
    readonly property string userDisplay: users.length > 0 ? users[userIndex].display : ""

    // ---------------------------------------------------------------- sessions

    // [{ id: "hyprland", name: "Hyprland", exec: "Hyprland" }, ...]
    property var sessions: []
    property int sessionIndex: 0
    readonly property var session: sessions.length > 0 ? sessions[sessionIndex] : null

    // The folder with the sessions' .desktop files. The NixOS module sets it; elsewhere it is
    // where most distributions keep them.
    readonly property string sessionsDir: Quickshell.env("SOL_SHELL_SESSIONS") || "/usr/share/wayland-sessions"

    // ---------------------------------------------------------------- the login

    // what has been typed into the password field
    property string typed: ""
    // why the last try failed ("Wrong password"), or ""
    property string error: ""
    // a message from the login (for example "Place your finger on the reader"), or ""
    property string notice: ""
    // true from pressing Enter until greetd has answered
    property bool checking: false
    // a try was started and its password has not been sent yet
    property bool waitingToAnswer: false

    function selectUser(index: int): void {
        if (checking || index < 0 || index >= users.length)
            return;
        userIndex = index;
        typed = "";
        error = "";
        notice = "";
    }

    function selectSession(index: int): void {
        if (index >= 0 && index < sessions.length)
            sessionIndex = index;
    }

    function nextSession(): void {
        if (sessions.length > 1)
            sessionIndex = (sessionIndex + 1) % sessions.length;
    }

    function submit(): void {
        if (checking || typed === "" || user === "" || !session)
            return;
        checking = true;
        error = "";
        notice = "";
        waitingToAnswer = true;
        Greetd.createSession(user);
    }

    Connections {
        target: Greetd

        // greetd asks something: the password, or tells something
        function onAuthMessage(message: string, isError: bool, responseRequired: bool, echoResponse: bool): void {
            if (responseRequired && root.waitingToAnswer) {
                root.waitingToAnswer = false;
                Greetd.respond(root.typed);
                root.typed = "";
            } else if (isError) {
                root.error = message;
            } else if (!responseRequired) {
                root.notice = message;
            }
        }

        function onAuthFailure(message: string): void {
            root.checking = false;
            root.waitingToAnswer = false;
            root.typed = "";
            // greetd has already ended this login; the next try starts a new one
            root.error = "Wrong password";
        }

        function onReadyToLaunch(): void {
            const chosen = root.session;
            root.remember();
            // greetd runs the command like a login shell would, so the session's Exec line
            // (which may have arguments) goes through sh
            Greetd.launch(["sh", "-c", chosen.exec], ["XDG_SESSION_TYPE=wayland", "XDG_SESSION_DESKTOP=" + chosen.id]);
        }

        function onError(message: string): void {
            // After a wrong password Quickshell cancels the login that greetd has already ended,
            // and greetd answers that with an error. It must not replace "Wrong password".
            if (!root.checking)
                return;
            root.checking = false;
            root.waitingToAnswer = false;
            root.typed = "";
            root.error = "Could not log in (" + message + ")";
        }
    }

    // ------------------------------------------------------------ list of users

    // `getent passwd` lists everybody, from files and from other sources (LDAP, ...). A
    // person has a user id of 1000 or more, and a shell that can log in.
    Process {
        running: true
        command: ["getent", "passwd"]

        stdout: StdioCollector {
            onStreamFinished: {
                const found = [];
                for (const line of text.split("\n")) {
                    const fields = line.split(":");
                    if (fields.length < 7)
                        continue;
                    const uid = parseInt(fields[2]);
                    const shell = fields[6];
                    if (uid < 1000 || uid >= 60000 || shell.endsWith("nologin") || shell.endsWith("/false"))
                        continue;
                    // the "real name" is the first part of the comment field
                    const real = fields[4].split(",")[0];
                    found.push({ name: fields[0], display: real !== "" ? real : fields[0] });
                }
                root.users = found;
                root.applyRemembered();
            }
        }
    }

    // ---------------------------------------------------------- list of sessions

    // One line per session, "id<TAB>Name<TAB>Exec", read from the .desktop files. Nothing is
    // pasted into the script text: the folder arrives as an argument.
    Process {
        running: true
        command: ["sh", "-c",
            'for f in "$1"/*.desktop; do [ -e "$f" ] || continue; ' +
            'printf "%s\\t%s\\t%s\\n" "$(basename "$f" .desktop)" ' +
            '"$(sed -n "s/^Name=//p" "$f" | head -n 1)" "$(sed -n "s/^Exec=//p" "$f" | head -n 1)"; done',
            "sh", root.sessionsDir]

        stdout: StdioCollector {
            onStreamFinished: {
                const found = [];
                for (const line of text.split("\n")) {
                    const fields = line.split("\t");
                    if (fields.length < 3 || fields[2] === "")
                        continue;
                    found.push({ id: fields[0], name: fields[1] !== "" ? fields[1] : fields[0], exec: fields[2] });
                }
                root.sessions = found;
                root.applyRemembered();
            }
        }
    }

    // ------------------------------------------------ the last user and session

    // The choice is kept between logins in a small file the module makes writable for the
    // greeter. Without it (or when it cannot be written) everything still works.
    readonly property string stateFile: Quickshell.env("SOL_SHELL_GREETER_STATE") || ""

    property var remembered: ({})

    function applyRemembered(): void {
        const lastUser = users.findIndex(u => u.name === remembered.user);
        if (lastUser >= 0)
            userIndex = lastUser;
        const lastSession = sessions.findIndex(s => s.id === remembered.session);
        if (lastSession >= 0)
            sessionIndex = lastSession;
    }

    function remember(): void {
        if (stateFile === "")
            return;
        rememberedFile.setText(JSON.stringify({ user: user, session: session ? session.id : "" }));
    }

    FileView {
        id: rememberedFile
        path: root.stateFile
        printErrors: false

        onLoaded: {
            try {
                root.remembered = JSON.parse(text());
                root.applyRemembered();
            } catch (e) {
                // a broken file just means "no choice remembered"
            }
        }
    }
}
