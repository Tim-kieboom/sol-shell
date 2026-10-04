import QtQuick
import QtQuick.Layouts

// A fixed gap in a RowLayout, `size` pixels wide (on top of the spacing the
// layout already puts between items). For a gap that stretches, use FillSpace.
Item {
    property real size: 0

    Layout.preferredWidth: size
}
