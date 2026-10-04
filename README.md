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
  - CPU and memory rings; click either for a small **task manager** (like htop and
    btop in miniature): CPU total, temperature and a bar per thread, load and
    uptime, memory in detail, every graphics card (use, memory, temperature,
    power) and the busiest programs by CPU or by memory
  - a Wi-Fi and Bluetooth popup (switches, network list with password prompt,
    paired devices)
- **Notifications**: the shell is the notification daemon, so apps (a browser,
  chat apps, `notify-send`) show up as cards in the top-right corner of the
  monitor you are using. They time out by themselves (critical ones stay until
  dismissed), pause while the mouse is over them, and a click dismisses them.
  A bell in the bar (with a badge for unread ones) opens the history, newest
  first, and has a **do not disturb** switch: while on, nothing pops up (critical
  ones still do) but everything is still recorded. Middle-click the bell to
  toggle do not disturb.

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

## Controlling it from outside

The shell listens for commands, so a Hyprland keybind can drive it. For example,
to toggle do not disturb (the other commands are `clear`, `count`, `unread`,
`list` and `dnd`; `qs ipc -p <path> show` lists everything. `sysmon summary`
prints the task manager numbers as text; it exists once the popup has been opened,
and shows "inactive" while the popup is closed):

```bash
qs ipc -p ~/.config/quickshell/sol-shell call notifications toggleDoNotDisturb
```

## Theming other programs

Whenever the theme changes (and at startup), `export/ThemeExporter.qml` fills in
the templates in `export/` with the theme's colors and writes the result to
`~/.local/state/theme/`. A template is the target file with `{{name}}`
placeholders (`{{background}}`, `{{accent}}`, ...; the list is `values` in
`ThemeExporter.qml`).

| Program | Template | Output | Use it with |
|---|---|---|---|
| Wofi | `export/wofi.css.tpl` | `~/.local/state/theme/wofi.css` | `wofi --show drun --style ~/.local/state/theme/wofi.css` |
| Dolphin | `export/kdeglobals.tpl` | `~/.local/state/theme/kdeglobals` | two links, see below |

Write the files again by hand with
`qs ipc -p ~/.config/quickshell/sol-shell call themeExport run`.

**Dolphin** (and other KDE programs) read their colors from `kdeglobals` and from
a named color scheme. Dolphin does not need Plasma for this, but it needs two
links, made once (the shell does not create files outside its own folders):

```bash
ln -s ~/.local/state/theme/kdeglobals ~/.config/kdeglobals
mkdir -p ~/.local/share/color-schemes
ln -s ~/.local/state/theme/kdeglobals ~/.local/share/color-schemes/SolShell.colors
```

A Dolphin that is already running only half follows a theme change (the file
area updates, the side panel does not), so restart it after switching theme. A
new window of a running Dolphin uses the colors that process started with.

## How it fits together

```
shell.qml            entry point: a wallpaper and a bar on every monitor
export/              templates and the exporter that themes other programs (wofi, dolphin)
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
- The task manager shows NVIDIA graphics cards (through `nvidia-smi`) and AMD ones
  (through `/sys`); Intel ones are not shown yet.
- Notifications: no action buttons yet, and the history lives in memory only (it
  is empty again after the shell restarts). Only one program can be the
  notification daemon, so do not run mako, dunst or similar next to this shell.
- Typing a Wi-Fi password relies on the popup's focus grab (`grabFocus` in
  `BarPopup`) to give it the keyboard. If typing does nothing on your setup,
  look there first.
- Quickshell 0.3.0 can crash in its live reload when many files change at the
  same moment (for example a script editing dozens of files). It restarts
  itself, so this only matters while developing.
