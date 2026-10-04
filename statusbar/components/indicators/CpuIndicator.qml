import "../../../singletons"

// CPU usage as a ring with a percentage next to it.
Indicator {
    resourceValue: SystemStats.cpuUsage
    iconText: Icons.cpu
    iconFontFamily: Fonts.materialIconFontFamily
    outputText: SystemStats.cpuFormatted
}
