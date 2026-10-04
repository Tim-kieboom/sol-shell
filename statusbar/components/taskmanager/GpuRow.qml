import QtQuick
import QtQuick.Layouts
import "../../../singletons"
import "../../../utils"

// One graphics card: its name and how busy it is, a bar for that, then its memory,
// power and temperature. `gpu` is one entry of SystemMonitorService.gpus.
ColumnLayout {
    id: root

    // { name, util, vramUsedKiB, vramTotalKiB, tempC, powerW }
    property var gpu

    // the small print under the bar, built from what this card reports
    readonly property string details: {
        if (!gpu)
            return "";
        const parts = [];
        if (gpu.vramTotalKiB > 0)
            parts.push(SystemMonitorService.formatKiB(gpu.vramUsedKiB) + " / " + SystemMonitorService.formatKiB(gpu.vramTotalKiB));
        if (gpu.tempC >= 0)
            parts.push(Math.round(gpu.tempC) + " \u00b0C");
        if (gpu.powerW >= 0)
            parts.push(Math.round(gpu.powerW) + " W");
        return parts.join("  \u00b7  ");
    }

    spacing: 3

    // name, and how busy it is
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            Layout.fillWidth: true
            // may shrink, or a long name would stretch the whole popup (see TaskManager)
            Layout.minimumWidth: 0
            text: root.gpu ? root.gpu.name : ""
            color: Theme.primaryText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.bodySmall
            elide: Text.ElideRight
        }

        Text {
            Layout.preferredWidth: 36
            horizontalAlignment: Text.AlignRight
            text: root.gpu ? Math.round(root.gpu.util * 100) + "%" : ""
            color: Theme.primaryText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.bodySmall
        }
    }

    MeterBar {
        Layout.fillWidth: true
        value: root.gpu ? root.gpu.util : 0
        barColor: Theme.usageColor(value)
    }

    // One line with the rest: memory, temperature and power, for whichever of them
    // the card reports ("2.3 / 24.0 GiB  \u00b7  45 \u00b0C  \u00b7  47 W").
    Text {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        text: root.details
        color: Theme.secondaryText
        font.family: Fonts.bodyFontFamily
        font.pixelSize: Fonts.labelSmall
        elide: Text.ElideRight
    }
}
