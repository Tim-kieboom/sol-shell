import QtQuick
import "../singletons"

// One side of the bar in the layout editor (left, center or right): its title and the entries in it.
// An entry is a chip, or a pill: a box with chips in it.
Column {
    id: root

    property string title
    // names, and lists of names (pills): what the layout file holds for this side
    property var entries: []

    spacing: 4

    Text {
        text: root.title
        color: Theme.secondaryText
        font.family: Fonts.bodyFontFamily
        font.pixelSize: Fonts.labelMedium
    }

    Rectangle {
        width: root.width
        implicitHeight: flow.implicitHeight + 16
        radius: 8
        color: Theme.shellBackground
        border.width: 1
        border.color: Theme.surfaceBorder

        Flow {
            id: flow
            x: 8
            y: 8
            width: parent.width - 16
            spacing: 6

            Repeater {
                model: root.entries

                Loader {
                    required property var modelData

                    sourceComponent: Array.isArray(modelData) ? pill : chip

                    Component {
                        id: chip
                        LayoutChip {
                            atom: modelData
                        }
                    }

                    // a pill: its own box on a line of its own, with the chips inside
                    Component {
                        id: pill
                        Rectangle {
                            width: flow.width
                            implicitHeight: inner.implicitHeight + 12
                            radius: 14
                            color: "transparent"
                            border.width: 1
                            border.color: Theme.accent

                            Flow {
                                id: inner
                                x: 6
                                y: 6
                                width: parent.width - 12
                                spacing: 6

                                Repeater {
                                    model: modelData

                                    LayoutChip {
                                        required property string modelData
                                        atom: modelData
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Text {
                visible: root.entries.length === 0
                text: "empty"
                color: Theme.mutedText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelSmall
            }
        }
    }
}
