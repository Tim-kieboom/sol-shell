# To do

Ideas for the bar, in the order I would build them. Each new item is an *atom*: one component in
`statusbar/components/`, a name in `BarRenderer.qml` and `BarStyle.atomNames`, and a place in the
styles (`statusbar/styles/`, both the normal and the compact layout).

## 1. Choose what is in the bar (settings)

A **Bar items** section in the settings window: a switch for each item, to hide the ones you do not
want. Do this first: the items below then get their switch for free.

- [ ] Save which items are hidden in `settings.json` (a `hiddenAtoms` list), and have the renderer
      leave those out, in every style and in the compact bar
- [ ] The settings item cannot be switched off (a style must keep it, see `BarStyle.requiredAtom`)
- [ ] Give every atom a name for people ("Wi-Fi", "Clock"), next to its id in `BarStyle`
- [ ] An island whose items are all hidden already goes away by itself (checked for media): check it
- [ ] Open: one list for all styles (simplest), or one per style?
- [ ] Open: do new items start on or off? (On changes your bar after an update; off hides them until
      you look)

## 2. New items

- [ ] **Launcher button**: opens wofi (installed; the shell already themes it). A second click
      closes it. Sits next to the power button.
- [ ] **Keyboard layout**: shows the active layout (`us`, `nl`) and switches on click. Read it from
      Hyprland (`hyprctl devices -j`, and the `activelayout` event for changes); switch with
      `hyprctl switchxkblayout`. Hide it when there is only one layout.
- [ ] **Night light**: a toggle for `hyprsunset` (installed). Easiest is for the shell to start and
      stop it itself; the temperature (about 4000 K) can be a setting later. Fits the compact menu
      as a row, or the bar as an icon.
- [ ] **Privacy indicator**: a dot or icon while a microphone, camera or screen share is in use,
      and which program. Needs PipeWire (`Quickshell.Services.Pipewire`): research how to tell an
      input stream from a camera or a screen capture. Hidden when nothing is in use.

## 3. Smaller things

- [ ] **CPU temperature in the popup**: the CPU popup already shows it when `k10temp` (AMD) or
      `coretemp` (Intel) is found, and this machine has `k10temp`. Check that it shows on the real
      shell. If it does not, that is a bug to fix; if you meant the temperature in the bar next to
      the CPU percentage, or the GPU's, say so.
- [ ] README: describe the new items, and a screenshot of each that the screenshot VM can show (it
      has no sound, camera or keyboard layouts to switch, so some will not appear)

## Not now

System tray, active window title, disk usage, network speed, uptime, power profile, update indicator.
