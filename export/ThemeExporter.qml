import Quickshell
import Quickshell.Io
import QtQuick
import "../singletons"

// Writes the active theme to config files that other programs read, so they follow
// the theme picked in the settings page. Each program has a template in this folder
// (wofi.css.tpl) with {{name}} placeholders. Every time the theme changes, the
// placeholders are replaced by the theme's colors and the result is written to
// ~/.local/state/theme/. Place one of these in shell.qml; it does its work by itself.
Scope {
    id: root

    readonly property string outputDir: Settings.homeDir + "/.local/state/theme"

    // The values the templates can use. Add a line here to offer a new placeholder.
    readonly property var values: ({
        background: hex(Theme.shellBackground),
        surface: hex(Theme.surface),
        border: hex(Theme.surfaceBorder),
        text: hex(Theme.primaryText),
        subtext: hex(Theme.secondaryText),
        muted: hex(Theme.mutedText),
        accent: hex(Theme.accent),
        accentHover: hex(Theme.accentHover),
        accentText: hex(Theme.accentText),
        success: hex(Theme.success),
        danger: hex(Theme.danger)
    })

    // "#rrggbb". Converted by hand so the result never depends on how a color
    // happens to print (a color with transparency would print as "#aarrggbb").
    function hex(c: color): string {
        const part = v => Math.round(v * 255).toString(16).padStart(2, "0");
        return "#" + part(c.r) + part(c.g) + part(c.b);
    }

    // Replace every {{name}} in a template. A name that does not exist is kept as
    // it is and reported, so a typo in a template is easy to spot.
    function render(template: string): string {
        return template.replace(/\{\{(\w+)\}\}/g, (whole, name) => {
            if (name in values)
                return values[name];
            console.warn("ThemeExporter: unknown placeholder " + whole);
            return whole;
        });
    }

    // true once the output folder exists; nothing is written before that
    property bool dirReady: false

    Process {
        running: true
        command: ["mkdir", "-p", root.outputDir]
        onExited: root.dirReady = true
    }

    // ---------------------------------------------------------------- wofi

    FileView {
        id: wofiTemplate
        path: Quickshell.shellPath("export/wofi.css.tpl")
    }

    FileView {
        id: wofiOutput
        path: root.outputDir + "/wofi.css"
        // we only write this file, so a missing file at first start is no problem
        printErrors: false
    }

    // Recomputed whenever the template loads or any color it uses changes
    readonly property string wofiCss: wofiTemplate.loaded ? render(wofiTemplate.text()) : ""

    onWofiCssChanged: writeWofi()
    onDirReadyChanged: writeWofi()

    function writeWofi(): void {
        if (dirReady && wofiCss !== "")
            wofiOutput.setText(wofiCss);
    }

    // Write everything again by hand:
    //   qs ipc -p ~/.config/quickshell/sol-shell call themeExport run
    IpcHandler {
        target: "themeExport"

        function run(): string {
            root.writeWofi();
            return wofiOutput.path;
        }
    }
}
