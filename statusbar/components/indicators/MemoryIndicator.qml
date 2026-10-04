import "../../../singletons"

// Memory in use as a ring with an amount in GiB next to it.
Indicator {
    resourceValue: SystemStats.usage
    iconText: Icons.memory
    iconFontFamily: Fonts.materialIconFontFamily
    outputText: SystemStats.usedFormatted
}
