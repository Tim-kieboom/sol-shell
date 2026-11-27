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
- [x] **Bar layout file** (`bar-layout.json`, step 1 of the layout control): `~/.config/quickshell/bar-layout.json`
      with `left`, `center` and `right` lists; an entry is an item name or a nested list (a pill).
      `singletons/BarLayoutService.qml` reads and checks it (watched, so a change shows at once) and
      `BarStyle.mergedSections` lays it over the style: each name takes the size and props the style gives
      that item, unlisted items are added back at the end of their default side (the ones that start
      hidden too, they stay hidden until switched on), and the compact bar takes out volume, color picker,
      Wi-Fi, Bluetooth and night light and puts the three-dots menu where the first of them was. One layout
      for all styles with a fixed gap rule (`itemSpacing` inside a pill, the island `gap` or the Minimal
      style's new `groupGap` between entries); on the islands bar a bare item gets a pill of its own, on the
      strip a pill is a plain run (`run` in `BarRenderer.qml`). A file that cannot be used is not used at
      all: the style's own layout is drawn and a card says why. Tested: six kinds of broken file (unknown
      item, item twice, bad JSON, wrong key, empty pill, not an object) each fall back and post one card,
      an empty or deleted file falls back, a fixed file is picked up again; and in the screenshot VM a
      layout was drawn on the minimal, islands and compact bars (`24` to `26` pictures) as described.
      Not tested: a layout on a real two-monitor setup, and `props` of an item in a pill the style
      never grouped.
- [x] **Layout editor** (step 4 of the layout control, the Layout tab of the settings), in three slices.
      (a) `settings/LayoutEditor.qml`: Customize makes `bar-layout.json` from the style's layout, Reset
      deletes it, and the three sides and the items not placed are shown. (b) Drag and drop: a pressed chip
      is followed by a copy of it (the proxy), the drop areas are the halves of every chip, the empty part
      of a pill and of a side, a "+ Pill" place and the "Not placed" box; the moves are plain functions in
      `utils/layoutMove.js` (tested on their own: `node tests/layoutMove.test.js utils/layoutMove.js`, 23
      cases). (c) Presets (the Minimal and Islands layouts, and a Dashboard) and layouts you save under a
      name (`~/.config/quickshell/bar-layouts/`, names of letters, digits, spaces, - and _ only), arrangement
      only; `sol-shell ipc call barlayout list/apply/save/remove`. Tested in the screenshot VM with real
      mouse drags: Volume moved before Power menu, a new pill made from Launcher, Workspaces dropped into
      it; Customize and Reset; and by IPC: saving, applying a preset and a saved layout, a broken saved
      layout is refused and leaves the layout in use alone, a missing one is refused, bad names are
      refused, delete. Found by the VM and fixed: a nested list loses its array-ness in a Repeater
      delegate, so a pill drew as a tiny chip. Not tested: a drop on the empty part of a side and on
      "Not placed" with the mouse (the logic is covered by the unit test), the presets and saved-layout
      buttons by mouse, and the editor on a real two-monitor setup.
- [x] **Bar position** (step 2 of the layout control): `barPosition` in the settings (`top`, `bottom`, or empty for
      the style's own), chosen with the Top and Bottom buttons in the Bar category or with
      `sol-shell ipc call barstyle place bottom`. `BarStyle.position` reads it, `Statusbar.qml` anchors by it,
      `BarPopup.qml` already opened upwards for a bottom bar, and `NotificationPopups.qml` now sits in the
      bottom-right corner with the newest card next to the corner. The volume popup stays at the bottom, 80
      pixels up, above a bottom bar. Tested in a test shell on the two real monitors: the bar windows move to
      the bottom edge and back, and a bad place is refused. Not tested by eye: the popups hanging upwards
      (the code was there, never used), the notification cards at the bottom, the Position buttons, and the
      volume popup above a bottom bar.
- [x] **Smooth style** (step 3 of the layout control, the end of it): `statusbar/styles/SmoothStyle.qml`, one soft
      rounded bar that floats 8 pixels from the screen edges (a third surface type, `floating`: the window
      is exactly the bar, with margins, and a rounded rectangle is its fill, so the whole window takes
      clicks and no click mask is needed). It has the minimal bar's items (BarStyle hands over
      `minimal.sections` and `compactSections`, so there is one layout for the two), a 38 pixel height, fully
      round ends, a popup gap of 10 and a default opacity of 0.9. Not the Caelestia screen frame (decided
      with the owner). Tested in a test shell on the two real monitors: it resolves with no problems, the
      bar windows are 8 pixels in from the edges at the top and at the bottom, and it loads with your own
      layout file (with a pill) and the compact bar; the shell logs no errors. Not tested by eye: how it
      looks, popups hanging from it, and the notification cards beside it.
- [x] **One place for the bar, slice 1** (the file and what draws it): `bar-layout.json` has `"version": 2`, the
      dropdown `{ "menu": [...] }` (at most one; only volume, wifi, bluetooth, colorPicker, nightLight and
      keepAwake) and an `"options"` map (clock and media `compact`, workspaces `monitorName`); an item the file
      does not list is hidden, except `settings`, which is always added. `BarStyle.mergedSections` turns it into
      what the bar draws (the dropdown is the three-dots item with an `items` list, `QuickSettings.qml` shows
      only those lines; the options are item properties, `Workspace.qml` got `showName`);
      `BarLayoutService.fromStyle` makes the starting layout of Customize from the style as drawn now (what is
      hidden stays out; with the old compact switch on, the five items become the dropdown and the clock
      and media are compact) and of the presets (without the items that start hidden). The hide chips and the
      compact switch of the Bar tab step aside while a layout is in use. `utils/layoutMove.js` knows the
      dropdown (an item that has no menu row is refused, and a second dropdown): 35 unit tests pass.
      Tested in a test shell on the real monitors: Customize in Minimal and Islands, compact or not, writes
      the expected file, and the shell logs no errors with a dropdown layout and with the settings open; eight
      kinds of broken file are refused with the right reason. Not tested by eye: how the dropdown and the
      options look in the bar and in the editor, and the dropdown's menu popup with fewer lines.
- [x] **One place for the bar, slice 2** (the editor): the Layout tab has the Style chips and the Position buttons at
      the top; a **+ Dropdown** button on each side (only while there is no dropdown) opens a place to drop
      the first item; the dropdown is drawn dashed and turns red, with a message, while you drag an item that
      has no line in its menu (`LayoutEditor.draggingFitsMenu`, and the move itself is refused by
      `utils/layoutMove.js`); the clock, media and workspaces chips have a badge that switches their option
      (`BarLayoutService.setOption`, `sol-shell ipc call barlayout option clock compact true`). Tested in a
      test shell with the settings open (no errors), and setting, clearing and refusing options by IPC. Not
      tested by eye or with the mouse: the badges, the dropdown place and its red state, and the Style and
      Position controls in the tab. The Bar tab still has its own copies of Style and Position until slice 3.
- [x] **One place for the bar, slice 3, the end of it**: the **Compact** preset (the layout of the style in use with its
      dropdown and the clock and media compact); the Bar tab is gone and its controls live in the Layout tab (the
      style and position at the top, the hide and show chips replaced by the Hidden box, the monitor-name toggle
      by the workspaces badge, the compact switch by the dropdown, the two compact badges and the preset);
      `settings/ItemChip.qml` is deleted. **Migration**: `BarLayoutService.migrateCompact` runs when both the
      layout file and the settings have been read: the old `compactBar` switch on with no layout file makes a
      layout from what the bar shows (customize: hidden items stay out, the five items go in the dropdown, the
      clock and media compact) and clears the switch; with a good file it only clears the switch; a file that
      cannot be used is not overwritten and the switch stays on. `Settings.loaded` is new. Tested in a test shell
      in four cases (switch on with no file on Islands, with a good file, with a broken file, and switch off with
      no file), and the Compact preset by IPC; the shell logs no errors with the settings open. Not tested by
      eye or with the mouse: the Layout tab as the one place, and the screenshot test, which is stale (see the
      TODO item above).
- [x] **Shutdown crash of the checkout shell, and a restart test** (the owner saw Quickshell crash on
      `sol-shell restart`). Three crash reports (one segfault, two aborts) were all in the shell being stopped, right
      after "Exiting due to IPC request". The segfault's stack showed the cause: on teardown each bar item
      removed itself from the click-mask list (`BarRenderer.removeMask`), which is the model of an
      Instantiator in `Statusbar.qml` that was being destroyed; it is fixed (`tearingDown` guard). The two
      aborts end in PipeWire cleanup after the quit and are not explained. Neither could be reproduced:
      13 start-and-kill cycles of a throwaway shell with a copy of the owner's settings and layout, and a VM
      (`tests/restart.nix`, six restarts as the only shell, islands bar) pass both with and without the fix. So the
      fix is unproven on the owner's desktop. `sol-shell restart` now says so when it leaves more than one shell
      (Quickshell's crash handler started the first duplicate), and `barstyle use <style>` is new. To check on the
      real desktop: restart three times and look at `ls -t ~/.cache/quickshell/crashes | head`.
- [x] **Move pills and the dropdown, and the dropdown inside a pill** (`utils/layoutMove.js`, the editor): a dropdown
      entry may now be one of the entries of a pill; `movedMenu` moves the dropdown (with its items) before or after
      an item, to the end of a side or of a pill, or into a pill of its own, never into itself; `movedPill` moves a whole
      pill (with the dropdown, if it holds it) before or after the entry of another item or the dropdown (`@menu`), or to
      the end of a side. In the editor a pill and the dropdown have a grip (`settings/LayoutGrip.qml`), the dropdown is its
      own component (`LayoutMenuBox.qml`) that sits on a side or in a pill, and a drag has a kind
      (`LayoutEditor.dragKind`: item, pill, dropdown) that decides where a drop goes (`dropOn`,
      `BarLayoutService.moveMenu` and `movePill`). 66 unit tests pass (31 new). Tested by driving the service
      (nine moves, each written to the file and read back, with the editor open and drawing the dropdown on a side and
      inside a pill without errors) and by checking bad files (a second dropdown, a clock in a dropdown inside a pill, a
      pill in a pill). Not tested by mouse or by eye: the grips, dragging a pill or the dropdown, and how the nested
      dropdown looks.
- [x] **Any item in the dropdown**: `utils/layoutMove.js` `MENU_ATOMS` is every item but the menu item (26; checked against
      `BarStyle.atomNames` at startup, and the file check says so for `quickSettings`). In `QuickSettings.qml` the six items that
      have a line keep it; any other item gets an "embedded" line: its name, and the item itself built from the bar's own
      atoms (`BarRenderer` hands them over as `atomComponents`), so it behaves as in the bar, and a line of an item that hides
      itself is not shown. Tested in a test shell: a dropdown with 17 mixed items loads, its 17 lines are built when the menu
      opens (opened and closed three times through a temporary hook, since removed), the shell stays up, the log is clean, and the
      default menu of six still works; 69 unit tests pass. Not tested: clicking an embedded item, in particular a popup that opens
      from an item inside the menu popup (a popup in a popup), nor how the lines look.

## Wallpaper fade and picker

- [x] A new wallpaper spreads over the old one as a growing circle (`wallpaper/WallpaperPicture.qml`, 700 ms, from the click in the picker or the middle; a second change finishes the first at once; also on the lock screen).
- [x] Full-screen picker `wallpaper/WallpaperPicker.qml` and `sol-shell ipc call wallpaper pick|next|previous`.
- [x] A wallpaper per monitor (`wallpaperByMonitor` in settings.json, `Settings.wallpaperFor` / `setWallpaper`): picker and `next`/`previous` act on the focused monitor, the settings page has a monitor row, the lock screen follows.
- [x] A wallpaper per workspace (`workspace:<id>` keys next to the monitor names in `wallpaperByMonitor`): workspace button in the settings row, `wallpaper pickWorkspace|nextWorkspace|previousWorkspace`.
- [x] Screenshot test measured again (`tests/screenshots.nix`): styles and presets by `barstyle use` / `barlayout apply`, checks that do not stop the run, new pictures (Layout tab, Appearance, dashboard at the bottom, wallpaper picker). README pictures retaken (all but `layout-islands.jpg`, which showed the empty-island problem above, and `compact.jpg`, whose click hit the bell: fixed to the menu button at x 1252, picture not retaken).
