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
    // Every color is available three ways: {{accent}} gives "#d1c88f" (for CSS),
    // {{accentRgb}} gives "209,200,143" (for KDE color schemes), and {{accentAlpha}}
    // gives "rgba(209, 200, 143, 0.80)" using the background opacity setting.
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
            table[name + "Alpha"] = rgba(colors[name], Settings.backgroundOpacity);
        }
        // "true" when backgrounds are see-through at all (Zen has to switch on
        // window transparency for that)
        table.transparency = Settings.backgroundOpacity < 1 ? "true" : "false";
        // "dark" or "light", for programs that need to know which kind of theme this
        // is. The palettes do not say, so it is judged by how bright the background is.
        const dark = luminance(Theme.shellBackground) < 0.5;
        table.scheme = dark ? "dark" : "light";
        // the same thing as a number, for Firefox's prefers-color-scheme setting
        table.contentScheme = dark ? "0" : "1";
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

    // "rgba(r, g, b, a)" as CSS reads it: the color with an opacity of 0.0 to 1.0
    function rgba(c: color, opacity: real): string {
        const a = Math.max(0, Math.min(1, opacity)).toFixed(2);
        return "rgba(" + [c.r, c.g, c.b].map(v => Math.round(v * 255)).join(", ") + ", " + a + ")";
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
        onExited: exitCode => {
            if (exitCode === 0)
                root.dirReady = true;
            else
                console.warn("sol-shell: cannot create", root.outputDir, "(theme files are not written)");
        }
    }

    // Programs whose colors we cannot change (Claude Desktop, other Electron and GTK4
    // apps) still follow the system's light/dark preference. That lives in dconf, and the
    // settings portal that those programs ask reads it from there. So, when the user has
    // switched it on (Settings.syncSystemColorScheme, off by default because it changes a
    // desktop-wide setting), the scheme is written there too, whenever it changes and
    // when the switch is turned on (and once at start).
    readonly property string scheme: values.scheme
    readonly property bool syncScheme: Settings.syncSystemColorScheme

    onSchemeChanged: applyScheme()
    onSyncSchemeChanged: applyScheme()
    Component.onCompleted: applyScheme()

    function applyScheme(): void {
        if (!syncScheme)
            return;
        // wait for a write that is still running; it starts again when it is done
        if (schemeWriter.running) {
            schemeWriter.again = true;
            return;
        }
        schemeWriter.again = false;
        schemeWriter.command = ["dconf", "write", "/org/gnome/desktop/interface/color-scheme",
            // dconf wants the value as text with quotes, e.g. 'prefer-dark'
            scheme === "dark" ? "'prefer-dark'" : "'prefer-light'"];
        schemeWriter.running = true;
    }

    Process {
        id: schemeWriter
        property bool again: false
        // a missing dconf is not an error worth more than a line in the log
        stderr: StdioCollector {}
        onExited: exitCode => {
            if (exitCode !== 0)
                console.warn("sol-shell: could not write the light/dark preference with dconf:", stderr.text.trim());
            if (again)
                root.applyScheme();
        }
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

    ThemeTarget {
        id: zenContent
        template: "zen-userContent.css.tpl"
        output: "zen-userContent.css"
        outputDir: root.outputDir
        ready: root.dirReady
        values: root.values
    }

    ThemeTarget {
        id: zenPrefs
        template: "zen-user.js.tpl"
        output: "zen-user.js"
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
            zenContent.write();
            zenPrefs.write();
            return root.outputDir;
        }
    }
}
