# To do

Ideas for the bar, in the order I would build them. Each new item is an *atom*: one component in
`statusbar/components/`, a name in `BarRenderer.qml` and `BarStyle.atomNames`, and a place in the
styles (`statusbar/styles/`, both the normal and the compact layout).

## 1. Choose what is in the bar (settings)

A **Bar items** section in the settings window: a switch for each item, to hide the ones you do not
want. Do this first: the items below then get their switch for free.

Done: the settings window has a **Bar items** section with a chip per item of the layout in use.

- [x] Save which items are hidden in `settings.json` (a `hiddenAtoms` list), and have the renderer
      leave those out, in every style and in the compact bar
- [x] The settings item cannot be switched off (a style must keep it, see `BarStyle.requiredAtom`)
- [x] Give every atom a name for people ("Wi-Fi", "Clock"), next to its id in `BarStyle`
- [x] An island whose items are all hidden goes away by itself, and the gaps close up
- [x] The settings window scrolls when it is taller than the screen
- [x] Decided: one list for all styles, and a new item starts shown (the list holds what you hide).
      A new item that should start hidden needs a "hidden by default" mark; not needed yet
- [x] The README screenshots of the settings window are taken again (and the screenshot script clicks the new places)

## 2. New items

- [x] **Launcher button**: opens wofi (installed; the shell already themes it). A second click
      closes it. Sits next to the power button. The command is `launcherCommand` in `settings.json`
      and `sol-shell ipc call launcher toggle` does the same for a keybind.
- [x] **Keyboard layout**: shows the active layout (`US`, `NL`) and switches on click (and on
      scroll). Read from `hyprctl devices -j` (the layouts, variants and the number in use), kept up
      to date by Hyprland's `activelayout` and `configreloaded` events; switched with
      `hyprctl switchxkblayout all next`. Decided: it is always shown, not hidden for one layout
      (this machine has only `us`, so it would never appear). Also `sol-shell ipc call keyboard ...`.
- [ ] **Night light**: a toggle for `hyprsunset` (installed). Easiest is for the shell to start and
      stop it itself; the temperature (about 4000 K) can be a setting later. Fits the compact menu
      as a row, or the bar as an icon.
- [ ] **Privacy indicator**: a dot or icon while a microphone, camera or screen share is in use,
      and which program. Needs PipeWire (`Quickshell.Services.Pipewire`): research how to tell an
      input stream from a camera or a screen capture. Hidden when nothing is in use.

## 3. Smaller things

- [x] A switch in the settings to hide the monitor name next to the workspaces (`showMonitorName`)
- [ ] **CPU temperature in the popup**: the CPU popup already shows it when `k10temp` (AMD) or
      `coretemp` (Intel) is found, and this machine has `k10temp`. Check that it shows on the real
      shell. If it does not, that is a bug to fix; if you meant the temperature in the bar next to
      the CPU percentage, or the GPU's, say so.
- [ ] README: describe the new items, and a screenshot of each that the screenshot VM can show (it
      has no sound, camera or keyboard layouts to switch, so some will not appear)

## Not now

System tray, active window title, disk usage, network speed, uptime, power profile, update indicator.
