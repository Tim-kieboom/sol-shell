import Quickshell
import QtQuick
import "./statusbar"
import "./wallpaper"
import "./notifications"
import "./export"

// Entry point: puts a wallpaper and a status bar on every monitor.
ShellRoot {
    // one wallpaper per monitor
    //
    // Variants makes one copy of what is inside it for every item in `model`.
    // Quickshell.screens is a live list of your monitors, so plugging in or
    // removing a monitor creates or destroys its windows automatically.
    Variants {
        model: Quickshell.screens

        Wallpaper {
            // Each copy receives its own item as `modelData` (here: one screen).
            // Assigning it to `screen` tells the window which monitor to appear on.
            required property var modelData
            screen: modelData
        }
    }

    // writes the theme for other programs (wofi, dolphin) to ~/.local/state/theme
    ThemeExporter {}

    // the notification popups: one window that follows your focus, not one per monitor
    NotificationPopups {}

    // one status bar per monitor (same pattern as above)
    Variants {
        model: Quickshell.screens

        Statusbar {
            required property var modelData
            screen: modelData
        }
    }
}
