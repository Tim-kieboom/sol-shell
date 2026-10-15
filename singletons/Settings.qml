pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Shell-wide settings and paths. What the user can change (theme, wallpaper) is
// saved to a JSON file in the shell's state directory and survives restarts.
Singleton {
    id: root

    readonly property real uiScale: 1.0

    readonly property string homeDir: Quickshell.env("HOME")
    // The login screen (greeter/) runs as another user, with no settings file of its own, and
    // must never create one: it only reads.
    readonly property bool readOnly: Quickshell.env("SOL_SHELL_GREETER") === "1"
    // the folder the wallpaper picker looks in
    readonly property string wallpaperDir: homeDir + "/Pictures/Wallpapers"

    // The wallpaper that ships with the project. resolvedUrl builds the full path
    // relative to THIS file, so it works wherever the project folder is.
    readonly property url defaultWallpaper: Qt.resolvedUrl("../wallpaper/Meisje_met_de_parel.jpg")
    // The shipped painting is portrait, so it is shown whole with bars at the sides. This
    // is the colour of its own edge (measured: about rgb(3, 2, 18)), so the bars and the
    // painting meet without a visible seam.
    readonly property color defaultWallpaperBackground: "#030212"

    // Turns a file path into a URL that an Image can load. Characters that mean
    // something inside a URL ("#" starts a fragment, "?" a query, "%" an escape)
    // must be encoded, or a file named "Summer #1.jpg" is looked up as "Summer ".
    // Each segment is encoded on its own so the "/" separators stay as they are.
    function fileUrl(path: string): url {
        return "file://" + path.split("/").map(encodeURIComponent).join("/");
    }

    // ---- things the user can change (saved between restarts) ----
    // An alias is a second name for a property that lives somewhere else. These
    // two look like normal properties to the rest of the shell, but reading and
    // writing them really reads and writes the saved settings below.
    // wallpaperFile is a full path, or "" which means "use the default above".
    property alias themeName: saved.theme
    property alias wallpaperFile: saved.wallpaper
    // true = notifications are not shown as popups (they still go to the history)
    property alias doNotDisturb: saved.doNotDisturb
    // How opaque the shell's backgrounds are: the bar, the popups, and the programs that
    // follow the theme (Wofi, Thunar, Zen). Below 1.0 they are see-through, and Hyprland
    // blurs what shows through. Changed in the settings page. Every bar style has its own
    // value (a see-through island on a wallpaper reads differently from a see-through strip),
    // so this only stores them; BarStyle works out the one in use, and keeps it within the
    // style's range (0 would make the bar invisible).
    //
    // The first value was a single `backgroundOpacity`, from when there was one bar style.
    // It is the minimalist style's: that is the style it was set for.
    function savedOpacity(style: string): var {
        const own = saved.opacityByStyle?.[style];
        if (typeof own === "number")
            return own;
        return style === "minimal" ? saved.backgroundOpacity : undefined;
    }
    function setSavedOpacity(style: string, value: real): void {
        saved.opacityByStyle = Object.assign({}, saved.opacityByStyle, {
            [style]: value
        });
        // keep the old key in step for the minimalist style, so going back to a version of
        // the shell from before the styles keeps the value
        if (style === "minimal")
            saved.backgroundOpacity = value;
    }

    // The name of the bar style (see singletons/BarStyle.qml). What is saved is what the user
    // asked for: when that style cannot be used the bar falls back to the minimalist one, but
    // this stays as it is, so fixing the style fixes the bar.
    property alias barStyle: saved.barStyle
    // true = the bar's compact layout: one icon for volume, color picker, wifi and bluetooth,
    // the clock without the date, the media controls without the title (each style says
    // what its compact layout is)
    property alias compactBar: saved.compactBar

    // The items of the bar the user has switched off (their names, like "wifi"). One list for every
    // bar style and for the compact bar: an item is hidden wherever it would be shown. The renderer
    // leaves them out; BarStyle keeps the settings item from ever being hidden.
    function atomHidden(atom: string): bool {
        return (saved.hiddenAtoms ?? []).includes(atom);
    }
    function setAtomHidden(atom: string, hidden: bool): void {
        const list = (saved.hiddenAtoms ?? []).filter(name => name !== atom);
        if (hidden)
            list.push(atom);
        saved.hiddenAtoms = list;
    }

    // The command the launcher button runs (see LauncherService): wofi with the colors of the
    // theme, as README.md describes. Change it by hand in settings.json to use another launcher.
    property alias launcherCommand: saved.launcherCommand

    // true = the theme's light or dark side is also written to the desktop-wide
    // preference (dconf), so programs the shell cannot color (Electron, GTK4) follow it.
    // Off by default: it changes a setting outside this shell.
    property alias syncSystemColorScheme: saved.syncSystemColorScheme

    // The file on disk, in a fixed folder under ~/.local/state (next to the theme files),
    // so it does not depend on where the shell is installed. FileView creates the folder
    // on the first write.
    FileView {
        path: root.homeDir + "/.local/state/sol-shell/settings.json"
        // a missing file on first run is expected and handled below, so no warning
        printErrors: false

        // JsonAdapter turns the JSON file into real QML properties, and back.
        // The values here are the defaults, used until the user changes them.
        adapter: JsonAdapter {
            id: saved
            property string theme: "solliom"
            property string wallpaper: ""
            property bool doNotDisturb: false
            property real backgroundOpacity: 0.8
            property var opacityByStyle: ({})
            property string barStyle: "minimal"
            property bool compactBar: false
            property var hiddenAtoms: []
            property string launcherCommand: "wofi --show drun --style ~/.local/state/theme/wofi.css"
            property bool syncSystemColorScheme: false
        }

        // pick up edits made to the file by hand
        watchChanges: true
        onFileChanged: reload()
        // any change to a property above is written to disk straight away
        onAdapterUpdated: if (!root.readOnly) writeAdapter()
        // first run: no file yet, so create it from the defaults
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                if (!root.readOnly)
                    writeAdapter();
            } else {
                console.warn("sol-shell: cannot read settings.json (using the defaults):", error);
            }
        }
        onSaveFailed: error => console.warn("sol-shell: cannot save settings.json:", error)
    }
}
