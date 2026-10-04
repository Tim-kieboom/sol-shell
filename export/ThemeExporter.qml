import Quickshell
import Quickshell.Io
import QtQuick
import "../singletons"

// Writes the active theme to config files that other programs read, so they follow
// the theme picked in the settings page. Each program has a template in this folder
// with {{name}} placeholders. Every time the theme changes, the placeholders are
// replaced by the theme's colors and the result is written to
// ~/.local/state/theme/ (see ThemeTarget). Place one of these in shell.qml; it
// does its work by itself.
Scope {
    id: root

    readonly property string outputDir: Settings.homeDir + "/.local/state/theme"

    // The colors the templates can use. Add a line here to offer a new one.
    // Every color is available twice: {{accent}} gives "#d1c88f" (for CSS), and
    // {{accentRgb}} gives "209,200,143" (for KDE color schemes).
    readonly property var colors: ({
        background: Theme.shellBackground,
        window: Theme.theme.searchBackgroundColor,
        surface: Theme.surface,
        border: Theme.surfaceBorder,
        text: Theme.primaryText,
        subtext: Theme.secondaryText,
        muted: Theme.mutedText,
        accent: Theme.accent,
        accentHover: Theme.accentHover,
        accentText: Theme.accentText,
        success: Theme.success,
        danger: Theme.danger
    })

    // The final name -> text table that the targets use
    readonly property var values: {
        const table = {};
        for (const name in colors) {
            table[name] = hex(colors[name]);
            table[name + "Rgb"] = rgb(colors[name]);
        }
        // "dark" or "light", for programs that need to know which kind of theme this
        // is. The palettes do not say, so it is judged by how bright the background is.
        table.scheme = luminance(Theme.shellBackground) < 0.5 ? "dark" : "light";
        return table;
    }

    // "#rrggbb". Converted by hand so the result never depends on how a color
    // happens to print (a color with transparency would print as "#aarrggbb").
    function hex(c: color): string {
        const part = v => Math.round(v * 255).toString(16).padStart(2, "0");
        return "#" + part(c.r) + part(c.g) + part(c.b);
    }

    // How bright a color looks, 0 (black) to 1 (white); green counts most, blue least
    function luminance(c: color): real {
        return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
    }

    // "r,g,b" with 0-255 numbers
    function rgb(c: color): string {
        return [c.r, c.g, c.b].map(v => Math.round(v * 255)).join(",");
    }

    // true once the output folder exists; nothing is written before that
    property bool dirReady: false

    Process {
        running: true
        command: ["mkdir", "-p", root.outputDir]
        onExited: root.dirReady = true
    }

    ThemeTarget {
        id: wofi
        template: "wofi.css.tpl"
        output: "wofi.css"
        outputDir: root.outputDir
        ready: root.dirReady
        values: root.values
    }

    ThemeTarget {
        id: dolphin
        template: "kdeglobals.tpl"
        output: "kdeglobals"
        outputDir: root.outputDir
        ready: root.dirReady
        values: root.values
    }

    ThemeTarget {
        id: gtk
        template: "gtk.css.tpl"
        output: "gtk.css"
        outputDir: root.outputDir
        ready: root.dirReady
        values: root.values
    }

    ThemeTarget {
        id: zen
        template: "zen-userChrome.css.tpl"
        output: "zen-userChrome.css"
        outputDir: root.outputDir
        ready: root.dirReady
        values: root.values
    }

    // Write everything again by hand:
    //   qs ipc -p ~/.config/quickshell/sol-shell call themeExport run
    IpcHandler {
        target: "themeExport"

        function run(): string {
            wofi.write();
            dolphin.write();
            gtk.write();
            zen.write();
            return root.outputDir;
        }
    }
}
