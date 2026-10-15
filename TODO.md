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
- [x] **Night light**: a moon in the bar that switches `hyprsunset` on and off (a line with a switch
      in the compact bar's menu). The shell starts and stops it; the state and the temperature
      (`nightLight`, `nightLightTemperature`, 4000 K) are saved, so it comes back after a restart.
      A failure turns it off with a red card. `sol-shell ipc call nightlight ...` for a keybind.
      A schedule (on at one time, off at another, in the settings: `nightLightSchedule`, `nightLightFrom`,
      `nightLightUntil`) is done too. Open: a slider for the temperature in the settings.
- [x] **Privacy indicator**: a red icon (microphone, camera, screen) while a program is using it, hidden
      otherwise, and a click lists which programs. Read from PipeWire: a link in the `Active` state,
      classified by where it starts (an `Audio/Source` is a microphone, a `Video/Source` a camera, a
      `Stream/Output/Video` a screen cast). Not counted: `Internal` streams, a program recording a
      speaker's monitor, and paused links. `sol-shell ipc call privacy status`.
      Tested with a private PipeWire and a fake camera (the camera path end to end); the microphone and
      screen rules were checked on their own, against the node classes real programs and portals use.
      The microphone was tried on a real machine by the user and works. Not tested against a real webcam
      or portal screen share.

## 3. Smaller things

- [x] A switch in the settings to hide the monitor name next to the workspaces (`showMonitorName`)
- [ ] **CPU temperature in the popup**: the CPU popup already shows it when `k10temp` (AMD) or
      `coretemp` (Intel) is found, and this machine has `k10temp`. Check that it shows on the real
      shell. If it does not, that is a bug to fix; if you meant the temperature in the bar next to
      the CPU percentage, or the GPU's, say so.
- [ ] README: describe the new items, and a screenshot of each that the screenshot VM can show (it
      has no sound, camera or keyboard layouts to switch, so some will not appear)

## 4. More items

- [x] **System tray** (`tray`): the icons of programs that run in the background; left click opens the
      program (or the menu of an item that only has a menu), right click the menu, middle click the
      second action, scroll is passed on. Programs that say they are `Passive` are left out. Hidden
      when there are none. Tested with three fake items on a private D-Bus (Active, NeedsAttention,
      Passive: two shown); the clicks and the menus were not tried against a real program.
- [x] **Uptime** (`uptime`) and **disk usage** (`disk`): from `/proc/uptime` and `df`. Disk shows
      the system disk, red from 90%, and its popup every disk. Both start hidden.
- [x] **Network speed** (`networkSpeed`): from `/proc/net/dev`, read only while an item is in the
      bar; the loopback, bridges, virtual cables and VPN tunnels are not counted. Starts hidden.
- [x] **Ethernet** in the Wi-Fi item: a cable icon next to the Wi-Fi one while a wired
      connection is up, a line in the Wi-Fi popup and in the compact menu.
- [x] **NixOS update** (`updates`): see the README. Not checked: a system that is not a flake in
      `/etc/nixos`, or whose nixpkgs is not a GitHub input (it says so in the popup).
- [x] Items that start hidden (`shownAtoms`, `BarStyle.hiddenByDefault`), and `sol-shell ipc call
      barstyle enable <item>` / `disable <item>`.

## Not now

Active window title, power profile, a slider for the night light temperature.
