# To do

Ideas for the bar, in the order I would build them. Each new item is an *atom*: one component in
`statusbar/components/`, a name in `BarRenderer.qml` and `BarStyle.atomNames`, and a place in the
styles (`statusbar/styles/`, both the normal and the compact layout).

## Next up

- [ ] **Brightness on-screen popup**: the OSD for the brightness keys. Waits for the brightness
      control below; the volume popup (`osd/Osd.qml`, `singletons/OsdService.qml`) is the model.
- [ ] **Wallpaper colors, next steps**: per-monitor wallpapers and a bigger picker with a live preview
      (the "From wallpaper" theme itself is done, see TODO-done.md). Also open for the theme: a light
      variant. (Remembering the last seed, so the theme does not flash the default accent at startup,
      was skipped: the owner does not use that theme.)
- [ ] **Bar layout control** (Caelestia-style). Decided in an interview with the owner, in this order:
      1. *Layout file*: `~/.config/quickshell/bar-layout.json` (watched, like `weather-location.json`) with
         three lists, `left`, `center` and `right`. An entry is an item name, or a nested list that is a
         **pill** (an island); a nested list is a run of items with no background in the Minimal style.
         One layout for all styles, with a fixed gap rule (a small gap inside a pill, a bigger one between
         pills) in place of the Minimal style's hand-tuned gaps. A broken file falls back to the default
         layout and shows a red card, it never breaks the bar.
         Items the file does not list are appended to their default side, except the ones that start
         hidden (`BarStyle.hiddenByDefault`); the settings show which items the layout does not use. The
         hide and show chips stay.
         Compact: it removes volume, color picker, Wi-Fi and Bluetooth from the layout and puts the
         three-dots menu where the first of them was.
      2. *Bar position*: top or bottom (`barPosition` setting). Popups open the other way when the bar is at
         the bottom, and the notification cards go to the bottom as well (decided); check the volume popup
         and the settings window against it.
      3. *A third style*: "Smooth", one soft floating rounded bar (not the Caelestia screen frame).
      4. *Editor*: a drag-and-drop editor in the settings window that writes the same file (second step,
         after the file works).
      Not in this: a vertical bar (see Out of scope).
- [ ] **Brightness control**: a slider or scroll control for the screen brightness (laptop panels
      through `brightnessctl`/sysfs, external monitors through DDC, e.g. `ddcutil`). Gives the OSD
      above a second thing to show.
- [ ] **Screenshot and screen-record button**: wraps `grim`/`slurp` and `wf-recorder`, and shows up in
      the privacy indicator while recording. Lowest priority, a keybind covers most of it.

## Smaller things

- [ ] **CPU temperature in the popup**: the CPU popup already shows it when `k10temp` (AMD) or
      `coretemp` (Intel) is found, and this machine has `k10temp`. Check that it shows on the real
      shell. If it does not, that is a bug to fix; if you meant the temperature in the bar next to
      the CPU percentage, or the GPU's, say so.
- [ ] More README pictures for the newer items that the VM can show: the volume popup needs a sound
      device (the VM has none), the Bluetooth battery needs a device, and the From wallpaper theme has
      a theme chip picture but no picture of the bar in it.

## Not now

Active window title, power profile, a slider for the night light temperature.

## Out of scope

Left out on purpose, not forgotten:

- A built-in app launcher (Wofi does it, themed by the shell).
- A dock.
- A clipboard manager: a keybind that opens `cliphist` through Wofi does the same with no QML to
  maintain.
- A "control center" panel of quick toggles (the compact bar's menu already covers part of it).
- A vertical bar on the left or right side of the screen. Every item is built for a horizontal strip
  (a wide clock, rows of text, popups that open below the bar), so a vertical bar would mean a vertical
  form of nearly every item, not a setting. The bar can go to the top or the bottom (see the layout
  item above).

