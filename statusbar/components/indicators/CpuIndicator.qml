import "../../../singletons"

Indicator {
    resourceValue: SystemStats.cpuUsage
    iconText: Icons.cpu
    iconFontFamily: Fonts.materialIconFontFamily
    outputText: SystemStats.cpuFormatted
}
