import "../../../singletons"

Indicator {
    resourceValue: SystemStats.usage
    iconText: Icons.memory
    iconFontFamily: Fonts.materialIconFontFamily
    outputText: SystemStats.usedFormatted
}
