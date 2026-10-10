import Quickshell
import "./greeter"

// The login screen. greetd starts this inside a small compositor (cage) as its own user,
// before anybody has logged in; see greeter.nix and the README. It is not part of the
// desktop shell (shell.qml): it only shares its look. It sits at the top of the folder, like
// shell.qml, because Quickshell only allows imports from inside the folder it was started in.
ShellRoot {
    GreeterWindow {}
}
