# To do

Ideas for the bar, in the order I would build them. Each new item is an *atom*: one component in
`statusbar/components/`, a name in `BarRenderer.qml` and `BarStyle.atomNames`, and a place in the
styles (`statusbar/styles/`, both the normal and the compact layout).

## Next up

- [ ] **Brightness on-screen popup**: the OSD for the brightness keys. Waits for the brightness
      control below; the volume popup (`osd/Osd.qml`, `singletons/OsdService.qml`) is the model.
- [ ] **One place for the bar: the Layout tab** (the Bar tab goes away). Decided in an interview with the owner:
      - The Layout tab holds everything about the bar: the style (Minimal, Islands, Smooth), the position
        (top, bottom), the three sides, and the items. The Bar tab and its chips are removed.
      - **One Hidden box** replaces both the hide chips and "Not placed": drag an item there to hide it. An
        item the file does not list is hidden (so a new version's new item stays out of the bar until you
        place it, and the Hidden box shows it). This replaces the earlier rule that unlisted items are
        appended.
      - **The global compact switch goes away.** Compact is done by the items: one **dropdown** (the three
        dots; one for now, the file leaves room for several later) that you drag items into, and a small
        compact toggle on the two items that have a compact form, the clock (time only) and the media
        controls (buttons only). The workspaces' "monitor name" option moves to its chip too. A **Compact
        preset** does all of it in one click (presets stay arrangement only).
      - The dropdown accepts **every item in the end, the six that have menu rows first** (volume, Wi-Fi,
        Bluetooth, color picker, night light, keep awake); the editor refuses the others with a visible
        "can't go here" until each gets a menu form.
      - File: `{ "left": [...], "center": [...], "right": [...] }` where an entry is a name, a pill (a nested
        list), the dropdown `{ "menu": ["volume", ...] }`, or an item with options (`{ "clock": { "compact":
        true } }`). The style and position stay in `settings.json`, set from the Layout tab.
      - Migration: `compactBar` on with no layout file applies the Compact preset once and clears the flag;
        `hiddenAtoms` and `shownAtoms` are used while there is no layout file, and "Customize" starts from
        the style's layout minus what is hidden now, so nothing appears or disappears.
      Slices: (1) and (2) DONE, see TODO-done.md: the file format, the dropdown and item options, unlisted
      items hidden, and the editor with the style and position, "+ Dropdown", the "can't go here" state and
      the option badges; (3) still to do: the Compact preset, the `compactBar` migration (compact on with no layout file applies the Compact preset
      once and clears the flag), and the removal of the Bar tab and of `compactBar`.
      Changed from the plan above: item options are a separate `"options"` map in the file (one entry per
      item), not `{ "clock": { ... } }` entries in the sides, and a layout file written for the earlier
      format (unlisted items added back) is read with the new rule (unlisted items hidden).
- [ ] **Wallpaper colors, next steps**: per-monitor wallpapers and a bigger picker with a live preview
      (the "From wallpaper" theme itself is done, see TODO-done.md). Also open for the theme: a light
      variant. (Remembering the last seed, so the theme does not flash the default accent at startup,
      was skipped: the owner does not use that theme.)
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

