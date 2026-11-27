import QtQuick
import QtQuick.Layouts
import "../singletons"

// The layout editor: where the items of the bar sit, written to bar-layout.json (see
// BarLayoutService). Without that file the bar is laid out by its style; "Customize" makes the file
// from the style's layout, and "Reset" deletes it again.
Column {
    id: root

    spacing: 10

    // the names the layout puts somewhere
    readonly property var placed: {
        const names = [];
        const layout = BarLayoutService.layout;
        if (!layout)
            return names;
        for (const side of ["left", "center", "right"]) {
            for (const entry of layout[side]) {
                for (const name of Array.isArray(entry) ? entry : [entry])
                    names.push(name);
            }
        }
        return names;
    }

    // items that are not placed sit at the end of the side where the style has them; the compact
    // menu is the compact bar's own
    readonly property var unplaced: BarStyle.atomNames.filter(name => !placed.includes(name) && name !== BarStyle.compactMenuAtom)

    Text {
        width: root.width
        wrapMode: Text.WordWrap
        text: BarLayoutService.active
            ? "Your own layout is in use (bar-layout.json). A box with a border is a pill."
            : "The bar is laid out by its style. Customize makes your own layout from it: you can then move the items between the sides and group them into pills."
        color: Theme.mutedText
        font.family: Fonts.bodyFontFamily
        font.pixelSize: Fonts.labelSmall
    }

    // the file exists but cannot be used
    Text {
        visible: BarLayoutService.problem !== ""
        width: root.width
        wrapMode: Text.WordWrap
        text: "bar-layout.json cannot be used: " + BarLayoutService.problem + ". Reset deletes it."
        color: Theme.danger
        font.family: Fonts.bodyFontFamily
        font.pixelSize: Fonts.labelSmall
    }

    Row {
        spacing: 8

        // Customize: only while the style's own layout is in use
        Rectangle {
            visible: !BarLayoutService.active && BarLayoutService.problem === ""
            width: customizeLabel.implicitWidth + 28
            height: 30
            radius: 15
            color: customizeMouse.containsMouse ? Theme.surface : "transparent"
            border.width: 2
            border.color: Theme.accent

            Text {
                id: customizeLabel
                anchors.centerIn: parent
                text: "Customize"
                color: Theme.primaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelMedium
            }

            MouseArea {
                id: customizeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: BarLayoutService.customize()
            }
        }

        // Reset: while a file exists, usable or not
        Rectangle {
            visible: BarLayoutService.active || BarLayoutService.problem !== ""
            width: resetLabel.implicitWidth + 28
            height: 30
            radius: 15
            color: resetMouse.containsMouse ? Theme.surface : "transparent"
            border.width: 1
            border.color: Theme.surfaceBorder

            Text {
                id: resetLabel
                anchors.centerIn: parent
                text: "Reset"
                color: Theme.primaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelMedium
            }

            MouseArea {
                id: resetMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: BarLayoutService.reset()
            }
        }
    }

    // the three sides, while your layout is in use
    LayoutZone {
        visible: BarLayoutService.active
        width: root.width
        title: "Left"
        entries: BarLayoutService.layout?.left ?? []
    }

    LayoutZone {
        visible: BarLayoutService.active
        width: root.width
        title: "Center"
        entries: BarLayoutService.layout?.center ?? []
    }

    LayoutZone {
        visible: BarLayoutService.active
        width: root.width
        title: "Right"
        entries: BarLayoutService.layout?.right ?? []
    }

    // items the layout does not place
    Column {
        visible: BarLayoutService.active && root.unplaced.length > 0
        width: root.width
        spacing: 4

        Text {
            text: "Not placed"
            color: Theme.secondaryText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.labelMedium
        }

        Flow {
            width: root.width
            spacing: 6

            Repeater {
                model: root.unplaced

                LayoutChip {
                    required property string modelData
                    atom: modelData
                    dim: true
                }
            }
        }

        Text {
            width: root.width
            wrapMode: Text.WordWrap
            text: "These are added at the end of the side where the style has them (the ones that start hidden stay hidden until switched on under Bar items)."
            color: Theme.mutedText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.labelSmall
        }
    }
}
