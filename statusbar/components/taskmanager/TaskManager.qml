import QtQuick
import QtQuick.Layouts
import "../../../singletons"
import "../../../utils"

// The contents of the task manager popup: what htop and btop show, in small. CPU
// (total, temperature, every thread, load), memory, and the busiest programs. The
// numbers come from SystemMonitorService, which reads them only while this is open.
ColumnLayout {
    id: root

    // which list the programs section shows: false = by CPU, true = by memory
    property bool byMemory: false
    readonly property var programs: byMemory ? SystemMonitorService.topByMemory
                                             : SystemMonitorService.topByCpu
    // the value of the top entry, so every row's bar is relative to the busiest
    readonly property real topValue: programs.length === 0 ? 1
        : (byMemory ? programs[0].rssKiB : programs[0].cpu)

    spacing: 12

    // Two text styles used over and over below. An inline component is a small
    // reusable piece defined right where it is used.
    component Heading: Text {
        color: Theme.primaryText
        font.family: Fonts.bodyFontFamily
        font.pixelSize: Fonts.titleSmall
        font.weight: Font.Medium
    }

    component Caption: Text {
        color: Theme.secondaryText
        font.family: Fonts.bodyFontFamily
        font.pixelSize: Fonts.labelSmall
    }

    // ================================================================ CPU
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Heading {
                text: "CPU"
            }

            Caption {
                Layout.fillWidth: true
                // Without this a Text in a layout never gets narrower than its whole
                // text, so a long model name stretched the whole popup past its edge
                // and cut off the right-hand side. With 0 it may shrink and elide.
                Layout.minimumWidth: 0
                text: SystemMonitorService.cpuModel
                elide: Text.ElideRight
            }

            Caption {
                visible: SystemMonitorService.cpuTempC >= 0
                text: Math.round(SystemMonitorService.cpuTempC) + " °C"
            }
        }

        // total use of all threads together
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MeterBar {
                Layout.fillWidth: true
                implicitHeight: 8
                value: SystemMonitorService.cpuTotal
                barColor: Theme.usageColor(SystemMonitorService.cpuTotal)
            }

            Text {
                Layout.preferredWidth: 36
                horizontalAlignment: Text.AlignRight
                text: Math.round(SystemMonitorService.cpuTotal * 100) + "%"
                color: Theme.primaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.bodySmall
            }
        }

        CoreGrid {}

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Caption {
                text: "Load " + SystemMonitorService.loadAverage.map(v => v.toFixed(2)).join("  ")
            }

            Item {
                Layout.fillWidth: true
            }

            Caption {
                text: "Up " + SystemMonitorService.formatUptime(SystemMonitorService.uptimeSeconds)
            }

            Caption {
                text: SystemMonitorService.processCount + " processes"
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Theme.surfaceBorder
    }

    // ============================================================== memory
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            Heading {
                Layout.fillWidth: true
                text: "Memory"
            }

            Caption {
                text: SystemMonitorService.formatKiB(SystemMonitorService.memUsedKiB)
                    + " of " + SystemMonitorService.formatKiB(SystemMonitorService.memTotalKiB)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MeterBar {
                Layout.fillWidth: true
                implicitHeight: 8
                value: SystemMonitorService.memUsedFraction
                barColor: Theme.usageColor(SystemMonitorService.memUsedFraction)
            }

            Text {
                Layout.preferredWidth: 36
                horizontalAlignment: Text.AlignRight
                text: Math.round(SystemMonitorService.memUsedFraction * 100) + "%"
                color: Theme.primaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.bodySmall
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Caption {
                text: "Available " + SystemMonitorService.formatKiB(SystemMonitorService.memAvailableKiB)
            }

            Caption {
                text: "Cached " + SystemMonitorService.formatKiB(SystemMonitorService.memCachedKiB)
            }

            Caption {
                text: "Free " + SystemMonitorService.formatKiB(SystemMonitorService.memFreeKiB)
            }
        }

        // Swap, only on machines that have some (this one has none configured)
        RowLayout {
            Layout.fillWidth: true
            visible: SystemMonitorService.swapTotalKiB > 0
            spacing: 8

            Caption {
                text: "Swap " + SystemMonitorService.formatKiB(SystemMonitorService.swapUsedKiB)
                    + " of " + SystemMonitorService.formatKiB(SystemMonitorService.swapTotalKiB)
            }

            MeterBar {
                Layout.fillWidth: true
                value: SystemMonitorService.swapUsedFraction
                barColor: Theme.usageColor(SystemMonitorService.swapUsedFraction)
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Theme.surfaceBorder
    }

    // ============================================================ programs
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Heading {
                Layout.fillWidth: true
                text: "Programs"
            }

            // two tabs: which list to show
            Repeater {
                model: [
                    { label: "CPU", memory: false },
                    { label: "Memory", memory: true }
                ]

                Text {
                    required property var modelData
                    readonly property bool selected: root.byMemory === modelData.memory

                    text: modelData.label
                    color: selected ? Theme.accent : Theme.secondaryText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.bodySmall
                    font.weight: selected ? Font.Medium : Font.Normal

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.byMemory = parent.modelData.memory
                    }
                }
            }
        }

        Caption {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            wrapMode: Text.Wrap
            text: root.byMemory
                ? "Share of all memory. Programs made of many processes are added up"
                : "Share of the whole processor (all " + SystemMonitorService.cpuThreads + " threads). Added up per program"
        }

        // The rows are made once; only what they show changes (the ranking shifts
        // every second). Rows past the end of the list are hidden and take no space.
        Repeater {
            model: SystemMonitorService.listSize

            ProcessRow {
                id: row

                required property int index
                readonly property var program: root.programs[index]

                Layout.fillWidth: true
                visible: program !== undefined
                name: program ? program.name : ""
                count: program ? program.count : 1
                // the share of the whole machine, so 100% would be every thread / all memory
                valueText: !program ? ""
                    : root.byMemory ? SystemMonitorService.formatPercent(program.rssKiB / SystemMonitorService.memTotalKiB)
                    : SystemMonitorService.formatPercent(program.cpu / 100 / SystemMonitorService.cpuThreads)
                // for memory the amount is shown too, small and grey, beside the percentage
                detailText: program && root.byMemory ? SystemMonitorService.formatKiB(program.rssKiB) : ""
                fraction: !program ? 0 : (root.byMemory ? program.rssKiB : program.cpu) / root.topValue
                barColor: Theme.accent
            }
        }
    }
}
