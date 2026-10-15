import QtQuick
import "../../singletons"

// What the color picker remembers: the text in its field, the color that makes, and the red,
// green and blue of it for the sliders. It lives apart from the picker's popup because the
// popup's contents are thrown away whenever it closes, and a picked color has to survive that.
QtObject {
    id: root

    // What is typed in the field.
    property string input: ""
    // the typed text as "#rrggbb", or "" while it is not a color
    readonly property string color: ColorPickerService.parseColor(input)

    // red, green and blue (0 to 255) of the last color the field held; the sliders show
    // these, so they stay where they were while what is typed is not a color
    property var channels: [0, 0, 0]
    onColorChanged: {
        if (color !== "")
            channels = ColorPickerService.channels(color);
    }

    // a slider was moved: set that one channel (0 to 1 along the slider) and keep the others
    function setChannel(index: int, fraction: real): void {
        const next = channels.slice();
        next[index] = Math.round(fraction * 255);
        input = ColorPickerService.fromChannels(next[0], next[1], next[2]);
    }
}
