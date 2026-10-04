import Quickshell
import QtQuick
import QtQuick.Layouts
import "../../../singletons"
import "../"

// The contents of the clock popup: a month calendar with week numbers, and the
// current weather underneath. Scroll over the calendar, or use the arrows, to
// move between months; click the month name to jump back to today. A new copy of
// this is built every time the popup opens, so it always starts on this month.
ColumnLayout {
    id: root

    spacing: 10

    // Today, for the highlight. The hour precision is plenty: it only has to
    // notice that midnight has passed.
    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }
    readonly property date today: clock.date

    // The month on show. These start out following today (a binding); the first
    // time you move to another month they are assigned a plain number instead.
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()   // 0 = January

    // The calendar always starts the week on Monday, and numbers the weeks the
    // ISO way (week 1 is the week with the first Thursday of the year).
    readonly property int columns: 8   // the week number, then Monday to Sunday
    readonly property int rows: 6      // six weeks always cover any month

    function showMonth(offset: int): void {
        // the Date constructor handles going past December or before January
        const d = new Date(viewYear, viewMonth + offset, 1);
        viewYear = d.getFullYear();
        viewMonth = d.getMonth();
    }

    function showToday(): void {
        viewYear = today.getFullYear();
        viewMonth = today.getMonth();
    }

    // The date shown in a day cell, where cell 0 is the top left one. The grid
    // starts on the Monday on or before the 1st of the month, so the first and
    // last rows hold a few days of the neighboring months.
    function cellDate(day: int): date {
        const startOffset = (new Date(viewYear, viewMonth, 1).getDay() + 6) % 7;
        return new Date(viewYear, viewMonth, 1 - startOffset + day);
    }

    // ISO week number of a date
    function isoWeek(date: date): int {
        const d = new Date(date.getFullYear(), date.getMonth(), date.getDate());
        // move to the Thursday of this week: it decides which year the week is in
        d.setDate(d.getDate() + 3 - ((d.getDay() + 6) % 7));
        const firstThursday = new Date(d.getFullYear(), 0, 4);
        return 1 + Math.round(((d - firstThursday) / 86400000 - 3 + ((firstThursday.getDay() + 6) % 7)) / 7);
    }

    function sameDay(a: date, b: date): bool {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
    }

    // ------------------------------------------------------------------ header

    RowLayout {
        Layout.fillWidth: true

        IconButton {
            text: Icons.previousMonth
            onClicked: root.showMonth(-1)
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Qt.formatDate(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy")
            color: Theme.primaryText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.titleSmall
            font.weight: Font.Medium

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.showToday()
            }
        }

        IconButton {
            text: Icons.nextMonth
            onClicked: root.showMonth(1)
        }
    }

    // ---------------------------------------------------------------- the grid

    GridLayout {
        id: grid

        Layout.fillWidth: true
        columns: root.columns
        columnSpacing: 2
        rowSpacing: 2
        // every column the same width, also the one with the week numbers
        uniformCellWidths: true

        // scrolling over the calendar changes the month
        WheelHandler {
            onWheel: event => root.showMonth(event.angleDelta.y > 0 ? -1 : 1)
        }

        // the header row: "wk", then the weekday names (Monday first)
        Repeater {
            model: root.columns

            Text {
                required property int index

                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                // 1 January 2024 was a Monday, so day 1..7 of that month are Monday..Sunday.
                // Formatted the same way as the clock in the bar, so they use the same language.
                text: index === 0 ? "wk" : Qt.formatDate(new Date(2024, 0, index), "ddd")
                color: Theme.mutedText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelSmall
            }
        }

        // 6 weeks of 8 cells: the week number, then its 7 days. A number as the
        // model gives the cells without rebuilding them when the month changes.
        Repeater {
            model: root.rows * root.columns

            Item {
                id: cell

                required property int index

                readonly property int column: index % root.columns
                readonly property bool isWeekNumber: column === 0
                // the day cell index: skip the week number column of every row
                readonly property date dayDate: root.cellDate(Math.floor(index / root.columns) * 7 + column - 1)
                readonly property bool isToday: !isWeekNumber && root.sameDay(dayDate, root.today)
                readonly property bool inMonth: dayDate.getMonth() === root.viewMonth

                Layout.fillWidth: true
                Layout.preferredHeight: 30

                // the highlight on today: a rounded square in the accent color
                Rectangle {
                    anchors.centerIn: parent
                    width: 28
                    height: 28
                    radius: 8
                    visible: cell.isToday
                    color: Theme.accent
                }

                Text {
                    anchors.centerIn: parent
                    text: cell.isWeekNumber
                        ? root.isoWeek(root.cellDate(Math.floor(cell.index / root.columns) * 7))
                        : cell.dayDate.getDate()
                    color: cell.isToday ? Theme.accentText
                        : cell.isWeekNumber ? Theme.mutedText
                        : cell.inMonth ? Theme.primaryText : Theme.mutedText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: cell.isWeekNumber ? Fonts.labelSmall : Fonts.bodySmall
                    font.weight: cell.isToday ? Font.Bold : Font.Normal
                }
            }
        }
    }

    // ----------------------------------------------------------------- weather

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Theme.surfaceBorder
    }

    // shown once there is weather
    ColumnLayout {
        Layout.fillWidth: true
        visible: WeatherService.configured && WeatherService.available
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: WeatherService.icon
                color: Theme.accent
                font.family: Fonts.materialIconFontFamily
                font.pixelSize: Fonts.headlineSmall
            }

            Text {
                text: WeatherService.degrees(WeatherService.temperature)
                color: Theme.primaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.titleLarge
                font.weight: Font.Medium
            }

            Text {
                Layout.fillWidth: true
                // minimumWidth 0 lets a long text shrink (elide) instead of
                // pushing the popup wider
                Layout.minimumWidth: 0
                elide: Text.ElideRight
                text: WeatherService.condition
                color: Theme.secondaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.bodyMedium
            }

            Text {
                text: "H " + WeatherService.degrees(WeatherService.high) + "  L " + WeatherService.degrees(WeatherService.low)
                color: Theme.mutedText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelMedium
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            elide: Text.ElideRight
            text: WeatherService.locationName
                + "  " + Icons.dot + "  feels like " + WeatherService.degrees(WeatherService.feelsLike)
                + "  " + Icons.dot + "  " + Math.round(WeatherService.humidity) + "% humidity"
                + (WeatherService.stale ? "  " + Icons.dot + "  may be out of date" : "")
            color: Theme.mutedText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.labelMedium
        }
    }

    // and when there is none, say why
    Text {
        Layout.fillWidth: true
        visible: !(WeatherService.configured && WeatherService.available)
        wrapMode: Text.WordWrap
        text: !WeatherService.configured ? "Set a weather location in " + WeatherService.locationPath
            : WeatherService.error !== "" ? "Weather unavailable (" + WeatherService.error + ")"
            : "Loading weather..."
        color: Theme.mutedText
        font.family: Fonts.bodyFontFamily
        font.pixelSize: Fonts.labelMedium
    }
}
