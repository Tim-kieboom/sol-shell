pragma Singleton

import Quickshell

// Icon glyphs by name (mostly Material Design Icons). Draw them with
// font.family: Fonts.materialIconFontFamily. Not every entry is used yet; this
// is the catalog to pick from.
Singleton {
    readonly property string power: "⏻"
    readonly property string nixos: "󱄅"
    readonly property string notifications: "󰂚"
    readonly property string notificationsOff: "󰂛"
    readonly property string wifi: "󰖩"
    readonly property string wifiOff: "󰖪"
    readonly property string bluetooth: "󰂯"
    readonly property string headphones: "󰋋"
    readonly property string mouse: "󰍽"
    readonly property string keyboard: "󰌌"
    readonly property string speaker: "󰓃"
    readonly property string phone: "󰄜"
    readonly property string gamepad: "󰊴"
    readonly property string wallpaper: "󰸉"
    readonly property string brightness: "󰃠"
    readonly property string lightMode: "󰖙"
    readonly property string darkMode: "󰖔"
    readonly property string close: "󰅖"
    readonly property string confirm: "󰄬"
    readonly property string alert: "󰀦"
    readonly property string lock: "󰌾"
    readonly property string passwordVisible: "󰈈"
    readonly property string passwordHidden: "󰈉"
    readonly property string wifiStrong: "󰤨"
    readonly property string wifiGood: "󰤥"
    readonly property string wifiWeak: "󰤢"
    readonly property string wifiNone: "󰤟"
    readonly property string previousMonth: "󰁍"
    readonly property string nextMonth: "󰁔"
    readonly property string volume: "󰕾"
    readonly property string volumeOff: "󰖁"
    readonly property string microphone: "󰍬"
    // the privacy indicator: a camera is in use, and the screen is being shared
    // (Material Design Icons camera, cast)
    readonly property string camera: "󰄀"
    readonly property string screenShare: "󰄤"
    readonly property string media: "󰎈"
    readonly property string emptyMedia: "󰝚"
    readonly property string previousTrack: "󰒮"
    readonly property string pause: "󰏤"
    readonly property string play: "󰐊"
    readonly property string nextTrack: "󰒭"
    // the media popup: shuffle on and off, and repeat off, the whole list, one track
    // (Material Design Icons shuffle-variant, shuffle-disabled, repeat-off, repeat, repeat-once)
    readonly property string shuffle: "󰒟"
    readonly property string shuffleOff: "󰒞"
    readonly property string repeatOff: "󰑗"
    readonly property string repeatAll: "󰑖"
    readonly property string repeatOne: "󰑘"
    // the items that show the machine: a wired connection, the disk, how long it has been on, an update
    // waiting, and the two arrows of the network speed
    // (Material Design Icons ethernet, harddisk, clock-outline, update, arrow-down, arrow-up)
    readonly property string ethernet: "󰈀"
    readonly property string disk: "󰋊"
    readonly property string uptime: "󰅐"
    readonly property string update: "󰚰"
    readonly property string arrowDown: "󰁅"
    readonly property string arrowUp: "󰁝"
    readonly property string cpu: "󰘚"
    readonly property string gpu: "󰢮"
    readonly property string temperature: "󰔏"
    readonly property string ultraviolet: "󰖨"
    readonly property string humidity: "󰖎"
    readonly property string airQuality: "󰌪"
    readonly property string memory: "󰍛"
    readonly property string activeWorkspace: "󰫢"
    readonly property string dot: "•"
    readonly property string restart: "󰜉"
    readonly property string sleep: "󰒲"
    readonly property string logout: "󰍃"
    readonly property string settings: "󰒓"
    // a moon: the night light (Material Design Icons weather-night)
    readonly property string nightLight: "󰖔"
    // a grid of squares: the launcher button in the bar (Material Design Icons apps)
    readonly property string launcher: "󰀻"
    // three dots: the quick settings menu in the compact bar (Material Design Icons dots-horizontal)
    readonly property string quickSettings: "󰇘"
    readonly property string colorScheme: "󰏘"
    readonly property string eyedropper: "󰈈"
    // a painter's palette: the color popup in the bar
    readonly property string palette: "󰏘"
    readonly property string opacity: "󰗌"
    readonly property string terminal: "󰆍"

    // weather conditions (see WeatherService.conditionIcon)
    readonly property string weatherSunny: "󰖙"
    readonly property string weatherNight: "󰖔"
    readonly property string weatherPartlyCloudy: "󰖕"
    readonly property string weatherNightPartlyCloudy: "󰼱"
    readonly property string weatherCloudy: "󰖐"
    readonly property string weatherFog: "󰖑"
    readonly property string weatherRainy: "󰖗"
    readonly property string weatherPouring: "󰖖"
    readonly property string weatherSnowy: "󰖘"
    readonly property string weatherSnowyHeavy: "󰙿"
    readonly property string weatherLightning: "󰖓"
    readonly property string weatherLightningRainy: "󰙾"
    readonly property string weatherWindy: "󰖝"
}
