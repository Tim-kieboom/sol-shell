# To do

Ideas for the bar, in the order I would build them. Each new item is an *atom*: one component in
`statusbar/components/`, a name in `BarRenderer.qml` and `BarStyle.atomNames`, and a place in the
styles (`statusbar/styles/`, both the normal and the compact layout).

## Next up

- [ ] **Brightness on-screen popup**: the OSD for the brightness keys. Waits for the brightness
      control below; the volume popup (`osd/Osd.qml`, `singletons/OsdService.qml`) is the model.
- [ ] **Colors from the wallpaper**: a generated theme (for example with `matugen`) that follows
      the wallpaper, next to the fixed themes, so changing the picture changes the bar and the
      programs the shell already colors. Caelestia-style. Not done yet: per-monitor wallpapers and a
      bigger picker with a live preview.
- [ ] **Brightness control**: a slider or scroll control for the screen brightness (laptop panels
      through `brightnessctl`/sysfs, external monitors through DDC, e.g. `ddcutil`). Gives the OSD
      above a second thing to show.
- [ ] **VPN indicator**: an item that shows while a VPN is up (WireGuard, Tailscale, NetworkManager
      VPN), with a click for which one. Hidden when there is none. Note the network speed item
      already ignores VPN tunnels, so the detection can share that interface list.
- [ ] **Keep-awake toggle (caffeine)**: a bar item that stops the screen from locking or sleeping
      (`systemd-inhibit` or the Wayland idle inhibitor). Starts hidden like uptime and disk.
- [ ] **Screenshot and screen-record button**: wraps `grim`/`slurp` and `wf-recorder`, and shows up in
      the privacy indicator while recording. Lowest priority, a keybind covers most of it.

## Smaller things

- [ ] **CPU temperature in the popup**: the CPU popup already shows it when `k10temp` (AMD) or
      `coretemp` (Intel) is found, and this machine has `k10temp`. Check that it shows on the real
      shell. If it does not, that is a bug to fix; if you meant the temperature in the bar next to
      the CPU percentage, or the GPU's, say so.
- [ ] README: describe the new items, and a screenshot of each that the screenshot VM can show (it
      has no sound, camera or keyboard layouts to switch, so some will not appear)

## Not now

Active window title, power profile, a slider for the night light temperature.

## Out of scope

Left out on purpose, not forgotten:

- A built-in app launcher (Wofi does it, themed by the shell).
- A dock.
- A clipboard manager: a keybind that opens `cliphist` through Wofi does the same with no QML to
  maintain.
- A "control center" panel of quick toggles (the compact bar's menu already covers part of it).
