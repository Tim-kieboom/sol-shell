# To do: done

The finished items, moved out of TODO.md.

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

## 5. Laptop

- [x] **Battery** (`battery`) and **power mode** (`powerMode`): UPower's display device and
      power-profiles-daemon, through Quickshell's UPower service. Both hide themselves on a machine
      without a battery. Not tried on a real battery (the machine they were written on is a desktop):
      `sol-shell ipc call battery status` shows the raw number to check the 0 to 1 assumption.
- [x] **Weather settings**: a Weather section in the settings (search a city, choose, Celsius or
      Fahrenheit), written to `weather-location.json`. Tested in the screenshot VM against a fake
      geocoding service.

## 6. Settings

- [x] **Settings sidebar**: the settings window has a sidebar (Appearance, Bar, Night light, Weather,
      System, About), a search field that looks through all of them, and an About page (version and
      update status). The window has a fixed size; each category scrolls inside it. Not done: Wi-Fi,
      Bluetooth and sound pages (they overlap with the control center under "Out of scope"). Open:
      `tests/screenshots.nix` still clicks the positions of the old one-column layout.
- [x] **Volume on-screen popup (OSD)**: `sol-shell ipc call osd volumeUp`, `volumeDown` and `mute`
      change the volume through `AudioService` (5% steps, up to 150%) and show a popup on the
      focused monitor for 1.5 seconds. Only the keys trigger it, not the bar's ring. Tested in a
      throwaway shell: the three commands change the real volume and mute as expected, and the
      shell logs no errors. Open: the three Hyprland binds are yours to add (README); the popup's
      look was checked by eye only; a held key repeating was not tried.
- [x] **Colors from the wallpaper**: a "From wallpaper" theme (`singletons/themes/Generated.qml`). The
      dominant color of the wallpaper (`wallpaper/WallpaperColors.qml`: a one-pixel window with a Canvas
      that samples the picture at 48x48 and picks the heaviest slice of the color wheel, ignoring gray
      and near-black pixels) is the seed; the accent takes its hue and the dark background, surfaces and
      text are tinted with it. No new dependency. Only runs while the theme is chosen. Tested: the shipped
      painting (warm tan), a blue, a green and a gray picture give the expected seeds, and the shell logs
      no errors. Not tested: switching the wallpaper while the theme is on, and how the theme looks.
      The chip's preview shows the default accent until the theme has been chosen once.
- [x] **VPN indicator** (`vpn`): a shield while a VPN is up, hidden when none is; a click lists them.
      `singletons/VpnService.qml` reads `/sys/class/net` every 3 seconds (only while an item exists):
      an interface counts when its UP flag is set (a working WireGuard interface says "unknown" as its
      state, so the flag is used) and its kernel type is WireGuard or PPP, or its name is one VPN
      programs use. Not counted: `tap` (virtual machines make them). `sol-shell ipc call vpn status`.
      Tested with a real WireGuard interface made with `ip link add wg-test type wireguard`: found, shown in the bar and listed in the popup, and gone again when removed; no
      real VPN, OpenVPN, Tailscale or NetworkManager connection was tried.
- [x] **Keep-awake toggle** (`keepAwake`): a coffee cup in the bar (and a line with a switch in the compact
      menu); starts hidden. `idle/KeepAwakeInhibitor.qml` is a one-pixel window with a Wayland
      `IdleInhibitor`; the state is saved (`keepAwake`), so it survives a shell restart, and there is no
      timer. `sol-shell ipc call keepawake ...`. Decided with the user: hypridle locks after 10 minutes and
      switches the screen off after 15, no suspend, and keep awake holds off both. Tested with a real
      hypridle (4 second timeout, two runs each): idle fires with keep awake off, never with it on.
      Not tested: the `dpms` lines in the README against a Hyprland with a Lua configuration, hypridle's
      own lock and screen-off from the config in the README, and the look of the item.
- [x] **Bluetooth battery in the bar**: the Bluetooth icon shows the lowest battery of the connected devices
      that report one, red from 20% (`BluetoothService.lowestBattery`); the compact menu line says it for a
      single device. The popup already showed each device's battery. Tested only as far as the shell
      loading without errors: the connected headphones report 20% through BlueZ, so the bar should read
      "20%" in red; the look was not checked, and no second device was tried.
- [x] **Screenshot test brought up to date** (`tests/screenshots.nix`): the settings clicks follow the sidebar
      layout (tabs at x 420, the window at x 342 to 938 and y 120 to 680), the night light and weather
      steps use their own tabs instead of scrolling, and two pictures were added: the Bar category
      (`22-settings-bar`) and the bar with a VPN (a WireGuard interface made as root in the VM) and keep
      awake switched on (`23-vpn-keep-awake`). The theme loop includes the From wallpaper chip and ends by
      putting the default theme back. `nix build .#screenshots -L` ran to the end in this checkout (about
      four minutes, KVM available) and every check in it passed; the README pictures were taken from
      that run and a new row shows the two new ones.

