# To do

Ideas for the bar, in the order I would build them. Each new item is an *atom*: one component in
`statusbar/components/`, a name in `BarRenderer.qml` and `BarStyle.atomNames`, and a place in the
styles (`statusbar/styles/`, both the normal and the compact layout).

## Next up

- [ ] **Brightness on-screen popup**: the OSD for the brightness keys. Waits for the brightness
      control below; the volume popup (`osd/Osd.qml`, `singletons/OsdService.qml`) is the model.
- [ ] **Wallpaper colors, next steps**: a bigger picker with a live preview
      (the "From wallpaper" theme itself is done, see TODO-done.md). Also open for the theme: a light
      variant. (Remembering the last seed, so the theme does not flash the default accent at startup,
      was skipped: the owner does not use that theme.)
- [ ] **Brightness control**: a slider or scroll control for the screen brightness (laptop panels
      through `brightnessctl`/sysfs, external monitors through DDC, e.g. `ddcutil`). Gives the OSD
      above a second thing to show.
- [ ] **Screenshot and screen-record button**: wraps `grim`/`slurp` and `wf-recorder`, and shows up in
      the privacy indicator while recording. Lowest priority, a keybind covers most of it.

## Smaller things

- [ ] **A pill whose items are all hidden still draws an empty island** (islands style): seen in the screenshot
      run with a layout pill of `vpn, bell, settings` while the VPN was off, where the `vpn` item gave an empty
      island next to the others. Hide a pill when nothing in it is shown.

- [ ] **Per-monitor theme, the rest**: the bar and its popups use their own monitor's colors. Still
      shell-wide (the focused monitor's): the notification popups, the volume popup, the settings
      window, the wallpaper picker and the lock screen (`Theme.forScreen(name)` and a `theme`
      property per file is how a file switches over, see `statusbar/`).

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

