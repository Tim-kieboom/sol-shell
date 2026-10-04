# sol-shell

A status bar and wallpaper for [Hyprland](https://hyprland.org), written in
[Quickshell](https://quickshell.org) (QML). It is also a learning project, so
many comments explain *why* the code is the way it is.

What you get, on every monitor:

- **Wallpaper**: your picture, or the bundled default.
- **Status bar** with
  - a power menu (shut down, restart, log out, each needing a second click to
    confirm) and a settings page to pick a **theme** and a **wallpaper**
  - Hyprland workspaces
  - media controls for whatever is playing (title, progress bar, previous,
    play/pause, next, click-to-seek, switching between players)
  - a volume ring (scroll to change, middle-click to mute, click for a mixer:
    volume sliders, the list of output devices to switch between, microphone)
    and the clock
  - CPU and memory usage
  - a Wi-Fi and Bluetooth popup (switches, network list with password prompt,
    paired devices)
- **Notification popups**: the shell is the notification daemon, so apps (a
  browser, chat apps, `notify-send`) show up as cards in the top-right corner of
  the monitor you are using. They time out by themselves (critical ones stay until
  dismissed), pause while the mouse is over them, and a click dismisses them.

## Requirements

- Quickshell **0.3.0** (developed and tested on 0.3.0 with Qt 6.11)
- **Hyprland**: workspaces and "log out" use it
- **NetworkManager** for Wi-Fi (the only network backend Quickshell supports)
- **BlueZ** for Bluetooth, **PipeWire** for volume
- a media player that supports MPRIS (Spotify, browsers, mpv, ...)
- the fonts **Material Design Icons** and **Symbols Nerd Font**

## Running it

```bash
quickshell -p ~/.config/quickshell/sol-shell
```

(There is also a Zed task for this in `.zed/tasks.json`.) Quickshell reloads
the shell by itself whenever you save a file. To see warnings and errors:

```bash
qs log -p ~/.config/quickshell/sol-shell
```

## Settings

The theme and the wallpaper are chosen in the power menu: click the NixOS icon,
then **Settings**. They are saved to
`~/.local/state/quickshell/by-shell/<id>/settings.json`, outside this folder, so
they are never committed. The file looks like this and can be edited by hand:

```json
{
    "theme": "solliom",
    "wallpaper": "/home/you/Pictures/Wallpapers/wallpaper_1.jpg"
}
```

- Themes: `solliom` (default), `catppuccin`, `gruvbox`, `nord`, `dracula`,
  `tokyonight`, `rosepine`, `everforest` and `catppuccin-latte` (a light theme).
- The picker lists the images in `~/Pictures/Wallpapers` (jpg, jpeg, png, webp).
  An empty wallpaper (`""`) means the bundled `wallpaper/sunsetWallpaper.jpg`,
  which is also used if your own picture is missing or broken.

## How it fits together

```
shell.qml            entry point: a wallpaper and a bar on every monitor
wallpaper/           the wallpaper window and the bundled default picture
statusbar/           the bar and everything in it
  components/          the bar's parts (media, clock, workspaces, popups, ...)
    indicators/        CPU and memory rings
    settings/          the settings page of the power menu
singletons/          shared state and services (one instance each)
  themes/              the color palettes
utils/               small reusable pieces (ring, switch, spacer)
```

The main idea is that **services hold state and the UI only displays it**:

- A *service* in `singletons/` (`MediaService`, `NetworkService`,
  `AudioService`, ...) reads the system and exposes plain properties
  (`MediaService.title`) and functions (`MediaService.next()`).
- A *component* in `statusbar/` binds to those properties and calls those
  functions. It never talks to the system directly.
- Settings and themes work the same way: the picker only writes
  `Settings.themeName`, and `Theme` (a binding on it) recolors everything.

### Building blocks worth knowing

- **`BarPopup`** is the popup that hangs below a bar item. Put your contents
  inside it and call `popup.toggle()` from the icon's click handler. The
  contents are only built while it is open.
- **`ListRow`** is a clickable line with an icon, a title and a status line,
  used for devices, networks and power actions.
- **`StatusRing`** draws a ring from a 0.0 to 1.0 value.

### Adding a theme

1. Copy `singletons/themes/Gruvbox.qml`, rename it and change the colors.
2. Add it to the `themes` list and add a property for it in
   `singletons/Theme.qml`.

It then shows up in the settings page.

## Known limits

- Hyprland only (workspace switching and log out use `hyprctl`/its IPC).
- Only the first Wi-Fi device is handled; wired connections are not shown.
- No lock or suspend entry in the power menu yet.
- Notifications: popups only so far (no history, do-not-disturb or action
  buttons yet). Only one program can be the notification daemon, so do not run
  mako, dunst or similar next to this shell.
- Typing a Wi-Fi password relies on the popup's focus grab (`grabFocus` in
  `BarPopup`) to give it the keyboard. If typing does nothing on your setup,
  look there first.
- Quickshell 0.3.0 can crash in its live reload when many files change at the
  same moment (for example a script editing dozens of files). It restarts
  itself, so this only matters while developing.
