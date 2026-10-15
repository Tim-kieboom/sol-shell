import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "../../singletons"
import "../../utils"

// One icon (three dots) that stands in for the volume ring, the color picker, wifi and
// bluetooth, for the compact bar. Click it for a menu with a line for each; a line opens what
// that item's own popup shows (the volume mixer, the networks, the devices, the color picker),
// with a back button to return to the menu.
Item {
    id: root

    // the monitor this bar is on (a color picked from a keybind opens the popup on this one
    // only if you are on it)
    required property string screenName

    // what the popup shows: "" is the menu, otherwise the id of one of the pages below
    property string page: ""

    // what the color picker remembers (see ColorPickerState)
    ColorPickerState {
        id: pickerState
    }

    // The lines of the menu. `id` picks the page, the rest is what the line shows.
    readonly property var pages: [
        {
            id: "volume",
            icon: AudioService.muted ? Icons.volumeOff : Icons.volume,
            title: "Volume",
            subtitle: AudioService.available ? (AudioService.muted ? "Muted" : Math.round(AudioService.volume * 100) + "%") : "No audio"
        },
        {
            id: "wifi",
            icon: NetworkService.enabled ? Icons.wifi : Icons.wifiOff,
            title: "Wi-Fi",
            subtitle: NetworkService.wiredConnected ? "Ethernet, " + NetworkService.statusText : NetworkService.statusText
        },
        {
            id: "bluetooth",
            icon: Icons.bluetooth,
            title: "Bluetooth",
            subtitle: BluetoothService.statusText
        },
        {
            id: "color",
            icon: Icons.palette,
            title: "Color picker",
            subtitle: pickerState.color
        },
        // not a page: a line with a switch (`toggle` is what a click does)
        {
            id: "nightLight",
            icon: Icons.nightLight,
            title: "Night light",
            subtitle: NightLightService.enabled ? "On, " + NightLightService.temperature + " K" : "Off",
            checked: NightLightService.enabled,
            toggle: () => NightLightService.toggle()
        }
    ]
    readonly property var currentPage: pages.find(p => p.id === page) ?? null

    implicitWidth: 26
    implicitHeight: 26

    Text {
        anchors.centerIn: parent
        text: Icons.quickSettings
        // brighter while hovered or while the popup is open
        color: popup.open || mouse.containsMouse ? Theme.accentHover : Theme.accent
        font.family: Fonts.materialIconFontFamily
        font.pixelSize: Fonts.titleSmall
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.toggle()
    }

    // A color picked with the eyedropper (or from a keybind) goes into the field, and the
    // popup comes back on that page. Every monitor has a bar, but only the one you are on
    // opens its popup.
    Connections {
        target: ColorPickerService

        function onPicked(color: string): void {
            pickerState.input = color;
            const focused = Hyprland.focusedMonitor;
            if (!focused || focused.name === root.screenName) {
                root.page = "color";
                popup.open = true;
            }
        }
    }

    // the pages: each is built only while it is shown, and thrown away when you leave it
    Component {
        id: volumePage
        VolumeMixer {}
    }
    Component {
        id: wifiPage
        WifiPanel {}
    }
    Component {
        id: bluetoothPage
        BluetoothPanel {}
    }
    Component {
        id: colorPage
        ColorPickerPanel {
            picker: pickerState
            onCloseRequested: popup.close()
        }
    }

    BarPopup {
        id: popup

        // this icon is near the right end of the bar: grow leftwards
        alignRight: true
        popupWidth: 300
        padding: 8

        // the next time it opens, it opens on the menu
        onOpenChanged: {
            if (!open)
                root.page = "";
        }

        // The contents. Built when the popup opens, destroyed when it closes.
        ColumnLayout {
            spacing: 6

            // ---------- header of a page: back button and title ----------
            RowLayout {
                visible: root.page !== ""
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
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
                        onClicked: root.page = ""
                    }
                }

                Text {
                    text: root.currentPage?.title ?? ""
                    color: Theme.primaryText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.titleSmall
                    font.weight: Font.Medium
                }
            }

            // ---------- the menu ----------
            ColumnLayout {
                visible: root.page === ""
                spacing: 2

                Repeater {
                    model: root.pages

                    ListRow {
                        required property var modelData

                        Layout.fillWidth: true
                        icon: modelData.icon
                        title: modelData.title
                        subtitle: modelData.subtitle
                        // a line with a switch does its thing; the others open their page
                        onClicked: modelData.toggle ? modelData.toggle() : root.page = modelData.id

                        // an arrow on the right: this line opens something
                        Text {
                            visible: !modelData.toggle
                            text: Icons.nextMonth
                            color: Theme.secondaryText
                            font.family: Fonts.materialIconFontFamily
                            font.pixelSize: Fonts.bodyLarge
                        }

                        // or a switch: this line turns something on and off
                        ToggleSwitch {
                            visible: !!modelData.toggle
                            checked: modelData.checked ?? false
                            onToggled: modelData.toggle()
                        }
                    }
                }
            }

            // ---------- the page ----------
            Loader {
                Layout.fillWidth: true
                active: root.page !== ""
                sourceComponent: ({
                        volume: volumePage,
                        wifi: wifiPage,
                        bluetooth: bluetoothPage,
                        color: colorPage
                    })[root.page] ?? null
            }
        }
    }
}
