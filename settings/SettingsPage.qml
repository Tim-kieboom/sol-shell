import Quickshell
import QtQuick
import QtQuick.Layouts
import "../singletons"
import "../utils"

// The settings page: a sidebar of categories on the left, the settings of the chosen one on the right,
// and a search field that looks through all of them. Every group of settings is a Column that
// shows itself when `shows()` says so, so adding a setting is adding it to a group.
Item {
    id: root

    // The popup listens to this and goes back to the menu
    signal back

    // ---------- categories and search ----------

    readonly property var categories: ["Appearance", "Bar", "Night light", "Weather", "System", "About"]
    property string category: "Appearance"
    readonly property string query: search.text.trim().toLowerCase()

    // is the group with this category and these search words on show? While something is typed in
    // the search field every group that matches is shown, whatever category is chosen.
    readonly property var groupWords: ({
        "Appearance": "theme colors transparency opacity dark light wallpaper background",
        "Bar": "bar style compact items hide monitor name workspaces",
        "Night light": "night light schedule evening warm hyprsunset",
        "Weather": "weather location city temperature celsius fahrenheit",
        "System": "problems warnings errors notifications cards",
        "About": "version update nixos sol-shell"
    })

    // is any group on show? (for the "Nothing matches" line)
    readonly property bool anyShown: categories.some(c => shows(c))

    function shows(group: string): bool {
        if (query === "")
            return group === category;
        return (group + " " + groupWords[group]).toLowerCase().includes(query);
    }

    implicitWidth: 580
    implicitHeight: 520

    // ---------- sidebar: back button, title and the categories ----------
    Column {
        id: sidebar
        x: 0
        y: 0
        width: 140
        spacing: 4

        Row {
            spacing: 8
            bottomPadding: 8

            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: backMouse.containsMouse ? Theme.surface : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: Icons.previousMonth
                    color: Theme.primaryText
                    font.family: Fonts.materialIconFontFamily
                    font.pixelSize: Fonts.bodyLarge
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.back()
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Settings"
                color: Theme.primaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.titleSmall
                font.weight: Font.Medium
            }
        }

        Repeater {
            model: root.categories

            Rectangle {
                id: tab
                required property string modelData
                readonly property bool current: root.query === "" && root.category === modelData

                width: sidebar.width
                height: 32
                radius: 8
                color: current ? Theme.surface : tabMouse.containsMouse ? Theme.withOpacity(Theme.surface, 0.5) : "transparent"
                border.width: current ? 1 : 0
                border.color: Theme.accent

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 12
                    text: tab.modelData
                    color: tab.current ? Theme.primaryText : Theme.secondaryText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.labelMedium
                }

                MouseArea {
                    id: tabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        search.text = "";
                        root.category = tab.modelData;
                    }
                }
            }
        }
    }

    // ---------- search ----------
    Rectangle {
        id: searchBox
        x: sidebar.width + 12
        y: 0
        width: root.width - x
        height: 32
        radius: 8
        color: Theme.shellBackground
        border.width: 1
        border.color: search.activeFocus ? Theme.accent : Theme.surfaceBorder

        TextInput {
            id: search
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.primaryText
            selectionColor: Theme.accent
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.labelMedium
            clip: true
            // Escape clears the search first; with nothing typed it closes the settings
            Keys.onEscapePressed: event => {
                if (text !== "")
                    text = "";
                else
                    root.back();
                event.accepted = true;
            }

            Text {
                visible: search.text === "" && !search.activeFocus
                anchors.verticalCenter: parent.verticalCenter
                text: "Search settings"
                color: Theme.mutedText
                font: search.font
            }
        }
    }

    // ---------- the settings of the chosen category ----------
    Flickable {
        id: scroller
        x: sidebar.width + 12
        y: searchBox.height + 12
        width: root.width - x
        height: root.height - y
        contentWidth: width
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        focus: true
        Keys.onEscapePressed: root.back()

        // back to the top when another category is chosen
        Connections {
            target: root
            function onCategoryChanged(): void { scroller.contentY = 0; }
        }

        Column {
            id: content
            width: scroller.width - 8
            spacing: 12

            // Shown only when the bar style you picked cannot be used (see BarStyle).
            Text {
                visible: BarStyle.fallbackReason !== ""
                width: content.width
                text: BarStyle.fallbackReason
                wrapMode: Text.WordWrap
                color: Theme.danger
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelSmall
            }

            Text {
                visible: root.query !== "" && !root.anyShown
                text: "Nothing matches \u201c" + search.text.trim() + "\u201d"
                color: Theme.mutedText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelMedium
            }

            // Appearance
            Column {
                width: content.width
                spacing: 12
                visible: root.shows("Appearance")

            SectionHeader {
                icon: Icons.colorScheme
                title: "Theme"
            }

            // A Flow lays items out left to right and wraps to a new line when the next one
            // would not fit, so any number of themes works (three chips fit per line).
            Flow {
                width: content.width
                spacing: 8

                Repeater {
                    // one chip per palette, straight from the list in Theme.qml
                    model: Theme.themes

                    ThemeChip {
                        required property var modelData
                        entry: modelData
                    }
                }
            }

            SectionHeader {
                icon: Icons.opacity
                title: "Transparency"
            }

            RowLayout {
                width: content.width
                spacing: 10

                VolumeSlider {
                    Layout.fillWidth: true
                    // the slider shows 0..1 along its length, the opacity runs from minOpacity to 1
                    value: (root.shownOpacity - root.minOpacity) / (1 - root.minOpacity)
                    onMoved: fraction => root.chooseOpacity(fraction)
                }

                Text {
                    // a fixed width, so the slider does not change length when "100%" becomes "95%"
                    Layout.preferredWidth: 38
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(root.shownOpacity * 100) + "%"
                    color: Theme.secondaryText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.labelMedium
                }
            }

            Text {
                width: content.width
                wrapMode: Text.WordWrap
                text: "Each bar style keeps its own value. The bar and popups change at once. Wofi, Thunar and Zen read it when they start."
                color: Theme.mutedText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelSmall
            }

            SectionHeader {
                icon: Icons.darkMode
                title: "Light or dark for other apps"
            }

            RowLayout {
                width: content.width
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: "Follow the theme in apps the shell cannot color (Electron, GTK4)"
                    color: Theme.secondaryText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.labelMedium
                }

                ToggleSwitch {
                    checked: Settings.syncSystemColorScheme
                    onToggled: Settings.syncSystemColorScheme = !Settings.syncSystemColorScheme
                }
            }

            Text {
                width: content.width
                wrapMode: Text.WordWrap
                text: "Off by default. Switched on, the theme's light or dark side is written to your desktop-wide preference (dconf), which changes it for all programs."
                color: Theme.mutedText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelSmall
            }

            SectionHeader {
                icon: Icons.wallpaper
                title: "Wallpaper"
            }

            // Many pictures will not fit, so the grid scrolls: as tall as its content,
            // up to 190px, then it scrolls.
            //
            // A GridView only creates the cells you can see (and reuses them while you
            // scroll), so a folder with hundreds of pictures costs the same as one with
            // twelve. A Repeater inside a Flickable would build a thumbnail for every
            // single image, visible or not.
            GridView {
                width: content.width
                height: Math.min(contentHeight, 190)
                // one cell = a 100px thumbnail plus 8px of space; three fit in a row
                cellWidth: 108
                cellHeight: 68
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                // ScriptModel compares the new list with the old one and only changes
                // the cells that differ. Without it, every rescan of the folder (which
                // happens each time this page opens) would rebuild every thumbnail.
                // "" first = the default tile, then the pictures found in the folder.
                model: ScriptModel {
                    values: [""].concat(WallpaperService.wallpapers)
                }

                delegate: WallpaperThumb {
                    required property string modelData
                    path: modelData
                }
            }

            Text {
                visible: WallpaperService.wallpapers.length === 0
                text: "No other images found in " + Settings.wallpaperDir
                color: Theme.mutedText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelSmall
                }
            }

            // Bar
            Column {
                width: content.width
                spacing: 12
                visible: root.shows("Bar")

            SectionHeader {
                icon: Icons.settings
                title: "Bar style"
            }

            Flow {
                width: content.width
                spacing: 8

                Repeater {
                    model: BarStyle.styleList

                    StyleChip {
                        required property var modelData
                        entry: modelData
                    }
                }
            }

            RowLayout {
                width: content.width
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: "Compact bar"
                    color: Theme.secondaryText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.labelMedium
                }

                ToggleSwitch {
                    checked: Settings.compactBar
                    onToggled: Settings.compactBar = !Settings.compactBar
                }
            }

            Text {
                width: content.width
                wrapMode: Text.WordWrap
                text: "One menu icon for volume, color picker, wifi and bluetooth. The clock shows only the time and the media controls only the buttons."
                color: Theme.mutedText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelSmall
            }

            SectionHeader {
                icon: Icons.quickSettings
                title: "Bar items"
            }

            // one chip for each item of the layout in use: click to hide it, click again to show it
            Flow {
                width: content.width
                spacing: 6

                Repeater {
                    model: BarStyle.layoutAtoms

                    ItemChip {
                        required property string modelData
                        atom: modelData
                    }
                }
            }

            Text {
                width: content.width
                wrapMode: Text.WordWrap
                text: "Click an item to hide it from the bar, and again to bring it back. The settings item stays: it is the way back here."
                color: Theme.mutedText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelSmall
            }

            RowLayout {
                width: content.width
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: "Monitor name next to the workspaces"
                    color: Theme.secondaryText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.labelMedium
                }

                ToggleSwitch {
                    checked: Settings.showMonitorName
                    onToggled: Settings.showMonitorName = !Settings.showMonitorName
                }
            }
            }

            // Night light
            Column {
                width: content.width
                spacing: 12
                visible: root.shows("Night light")

            SectionHeader {
                icon: Icons.nightLight
                title: "Night light"
            }

            RowLayout {
                width: content.width
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: "Switch on and off by the clock"
                    color: Theme.secondaryText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.labelMedium
                }

                ToggleSwitch {
                    checked: Settings.nightLightSchedule
                    onToggled: Settings.nightLightSchedule = !Settings.nightLightSchedule
                }
            }

            // the two times; dim while the schedule is off
            RowLayout {
                width: content.width
                opacity: Settings.nightLightSchedule ? 1.0 : 0.5

                Text {
                    Layout.fillWidth: true
                    text: "On at"
                    color: Theme.secondaryText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.labelMedium
                }

                TimeField {
                    value: Settings.nightLightFrom
                    onCommitted: text => Settings.nightLightFrom = text
                }
            }

            RowLayout {
                width: content.width
                opacity: Settings.nightLightSchedule ? 1.0 : 0.5

                Text {
                    Layout.fillWidth: true
                    text: "Off at"
                    color: Theme.secondaryText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.labelMedium
                }

                TimeField {
                    value: Settings.nightLightUntil
                    onCommitted: text => Settings.nightLightUntil = text
                }
            }

            Text {
                width: content.width
                wrapMode: Text.WordWrap
                text: "With this on, the night light starts and stops at these times (they can run past midnight). You can still switch it by hand with the moon; the times take over again at the next one."
                color: Theme.mutedText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelSmall
            }
            }

            // Weather
            Column {
                width: content.width
                spacing: 12
                visible: root.shows("Weather")

            SectionHeader {
                icon: Icons.weatherPartlyCloudy
                title: "Weather"
            }

            WeatherSettings {
                width: content.width
            }
            }

            // System
            Column {
                width: content.width
                spacing: 12
                visible: root.shows("System")

            SectionHeader {
                icon: Icons.alert
                title: "Problems"
            }

            RowLayout {
                width: content.width
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: "Show the shell's warnings and errors as cards"
                    color: Theme.secondaryText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.labelMedium
                }

                ToggleSwitch {
                    checked: Settings.notifyProblems
                    onToggled: Settings.notifyProblems = !Settings.notifyProblems
                }
            }

            Text {
                width: content.width
                wrapMode: Text.WordWrap
                text: "Off by default. Each message shows once, a few at a time. All of them: sol-shell problems."
                color: Theme.mutedText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelSmall
            }
            }

            // About
            Column {
                width: content.width
                spacing: 12
                visible: root.shows("About")

                SectionHeader {
                    icon: Icons.settings
                    title: "About"
                }

                Text {
                    width: content.width
                    wrapMode: Text.WordWrap
                    text: "sol-shell " + (VersionService.version !== "" ? VersionService.display : "(unknown version)")
                    color: Theme.secondaryText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.labelMedium
                }

                Text {
                    width: content.width
                    wrapMode: Text.WordWrap
                    text: UpdateService.updateAvailable ? "A newer nixpkgs is available: " + UpdateService.shortRevision(UpdateService.runningRevision) + " to " + UpdateService.shortRevision(UpdateService.remoteRevision) + " (" + UpdateService.branch + ")." : UpdateService.restartNeeded ? "The system was rebuilt: restart to run the newest kernel." : UpdateService.failure !== "" ? "Update check: " + UpdateService.failure : "No NixOS update to report."
                    color: Theme.mutedText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.labelSmall
                }
            }
        }
    }
}
