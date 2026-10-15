import Quickshell
import QtQuick
import "./statusbar"
import "./wallpaper"
import "./notifications"
import "./lock"
import "./export"
import "./settings"
import "./singletons"

// Entry point: puts a wallpaper and a status bar on every monitor.
ShellRoot {
    // Singletons are only built when something first uses them. The launcher's command for a
    // keybind (`sol-shell ipc call launcher toggle`) has to be there whether or not the button
    // is in the bar, and before anyone has clicked it, so it is used here.
    // The keyboard layout's and the night light's commands for a keybind need the same. The night
    // light also has to come back after a restart if it was on, which it only does once it exists.
    // The update check has to be running whether or not its icon is in the bar.
    Component.onCompleted: {
        LauncherService.command;
        KeyboardLayoutService.count;
        NightLightService.enabled;
        PrivacyService.anyActive;
        UpdateService.anyActive;
    }

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

    // writes the theme for other programs (wofi, dolphin, thunar, zen) to ~/.local/state/theme
    ThemeExporter {}

    // the screen lock (nothing happens until LockService.locked becomes true)
    SessionLock {}

    // the settings window (hidden until SettingsService.open becomes true)
    SettingsWindow {}

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
