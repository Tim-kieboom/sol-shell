pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property real uiScale: 1.0

    readonly property string userPath: Quickshell.env("HOME")
    // the folder the wallpaper picker looks in
    readonly property string wallpaperDir: userPath + "/Pictures/Wallpapers"

    // The wallpaper that ships with the project. resolvedUrl builds the full path
    // relative to THIS file, so it works wherever the project folder is.
    readonly property url defaultWallpaper: Qt.resolvedUrl("../wallpaper/sunsetWallpaper.jpg")

    // Turns a file path into a URL that an Image can load. Characters that mean
    // something inside a URL ("#" starts a fragment, "?" a query, "%" an escape)
    // must be encoded, or a file named "Summer #1.jpg" is looked up as "Summer ".
    // Each segment is encoded on its own so the "/" separators stay as they are.
    function fileUrl(path: string): url {
        return "file://" + path.split("/").map(encodeURIComponent).join("/");
    }

    // ---- things the user can change (saved between restarts) ----
    // wallpaperFile is a full path, or "" which means "use the default above"
    // An alias is a second name for a property that lives somewhere else. These
    // two look like normal properties to the rest of the shell, but reading and
    // writing them really reads and writes the saved settings below.
    property alias themeName: saved.theme
    property alias wallpaperFile: saved.wallpaper

    // The file on disk. statePath() is a per-shell folder under ~/.local/state,
    // so this never ends up inside your project (and never in git).
    FileView {
        path: Quickshell.statePath("settings.json")
        // a missing file on first run is expected and handled below, so no warning
        printErrors: false

        // JsonAdapter turns the JSON file into real QML properties, and back.
        // The values here are the defaults, used until the user changes them.
        adapter: JsonAdapter {
            id: saved
            property string theme: "solliom"
            property string wallpaper: root.wallpaperDir + "/wallpaper_1.jpg"
        }

        // pick up edits made to the file by hand
        watchChanges: true
        onFileChanged: reload()
        // any change to a property above is written to disk straight away
        onAdapterUpdated: writeAdapter()
        // first run: no file yet, so create it from the defaults
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }
    }
}
