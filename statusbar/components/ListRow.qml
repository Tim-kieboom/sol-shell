import QtQuick
import QtQuick.Layouts
import "../../singletons"

// One clickable line in a popup: an icon, a title with an optional line of
// smaller text under it, and optionally extra items on the right.
//
//     ListRow {
//         icon: Icons.headphones
//         title: "My headphones"
//         subtitle: "Connected"
//         onClicked: ...
//
//         Text { text: "extra item on the right" }   // goes into `trailing`
//     }
//
// Used by the bluetooth devices, the wifi networks and the power menu, so they
// all look and behave the same.
Rectangle {
    id: root

    // ---- content ----
    property string icon
    property color iconColor: Theme.accent
    property string title
    // left empty, the line is hidden and takes no space
    property string subtitle
    property color subtitleColor: Theme.secondaryText

    // ---- look ----
    property real iconSize: Fonts.titleSmall
    property real titleSize: Fonts.bodySmall
    property real sideMargin: 8
    property real gap: 10

    // The row shows `highlightColor` while the mouse is over it, or all the time
    // when `highlighted` is true (for example: the row being edited, or armed).
    property bool highlighted: false
    property color highlightColor: Theme.nonAccent
    // set to false for a row that should not react to hovering
    property bool hoverHighlight: true

    signal clicked

    // Items placed inside a ListRow end up here, at the right edge.
    default property alias trailing: trailingRow.data

    implicitHeight: 38
    radius: 8
    color: highlighted || (hoverHighlight && mouse.containsMouse) ? highlightColor : "transparent"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.sideMargin
        anchors.rightMargin: root.sideMargin
        spacing: root.gap

        Text {
            text: root.icon
            color: root.iconColor
            font.family: Fonts.materialIconFontFamily
            font.pixelSize: root.iconSize
        }

        // title above, status below. fillWidth gives it all the space the icon and
        // the trailing items leave over, and a long title is cut off with "...".
        Column {
            Layout.fillWidth: true

            Text {
                width: parent.width
                text: root.title
                color: Theme.primaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: root.titleSize
                elide: Text.ElideRight
            }

            // only exists (and only takes space) when there is something to say
            Text {
                visible: root.subtitle !== ""
                width: parent.width
                text: root.subtitle
                color: root.subtitleColor
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelSmall
                elide: Text.ElideRight
            }
        }

        Row {
            id: trailingRow
            spacing: 8
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        // without this, containsMouse stays false until a button is pressed
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
