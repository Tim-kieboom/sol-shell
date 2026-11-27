import QtQuick
import QtQuick.Layouts
import "../../../singletons"
import "../../../utils"

// One program in the process list: its name (and how many processes it is made
// of), a value on the right, and a thin bar showing it against the busiest one.
ColumnLayout {
    // this monitor's colors
    readonly property var theme: Theme.forScreen(Window.window?.screen?.name ?? "")
    id: root

    property string name
    // how many processes this program consists of; shown as "x14" when above one
    property int count: 1
    // the value, already formatted ("0.7%")
    property string valueText
    // optional extra, small and grey, left of the value ("4.4 GiB")
    property string detailText
    // 0.0 to 1.0, relative to the top entry of the list
    property real fraction: 0
    property color barColor: theme.accent

    spacing: 2

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Text {
            Layout.minimumWidth: 0
            Layout.fillWidth: true
            text: root.name
            color: theme.primaryText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.bodySmall
            elide: Text.ElideRight
        }

        Text {
            visible: root.count > 1
            text: "x" + root.count
            color: theme.mutedText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.labelSmall
        }

        Text {
            visible: root.detailText !== ""
            text: root.detailText
            color: theme.mutedText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.labelSmall
        }

        Text {
            Layout.preferredWidth: 44
            horizontalAlignment: Text.AlignRight
            text: root.valueText
            color: theme.secondaryText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.bodySmall
        }
    }

    MeterBar {
        Layout.fillWidth: true
        implicitHeight: 3
        value: root.fraction
        barColor: root.barColor
    }
}
