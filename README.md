# sol-shell

![sol-shell: the bar, notifications and the default wallpaper](docs/screenshots/hero.jpg)

A desktop shell for [Hyprland](https://hyprland.org): a status bar with popups,
notifications and a wallpaper on every monitor, built with
[Quickshell](https://quickshell.org) (QML). Install it as a flake input on NixOS, pick
a theme, and it also colors your other programs. The code is commented throughout to
explain *why* it is the way it is, which makes it easy to change.

What you get, on every monitor:

- **Wallpaper**: your picture, or the bundled default.
- **Status bar** with
  - a power menu (lock, suspend, and shut down, restart and log out, which each need a
    second click to confirm) and a settings page to pick a **theme** and a **wallpaper**
  - Hyprland workspaces
  - media controls for whatever is playing (title, progress bar, previous,
    play/pause, next, click-to-seek, switching between players)
  - a volume ring (scroll to change, middle-click to mute, click for a mixer:
    volume sliders, the list of output devices to switch between, microphone)
  - the clock with the **temperature** next to it; click either for a **calendar**
    (month view with week numbers, scroll to change month, click the month name
    to go back to today) and the weather: conditions now, high and low, feels
    like, humidity, and a **5-day forecast** (conditions, high, low, chance of rain).
    The place is set in `~/.config/quickshell/weather-location.json`
    (see below)
  - CPU and memory rings; click either for a small **task manager** (like htop and
    btop in miniature): CPU total, temperature and a bar per thread, load and
    uptime, memory in detail, every graphics card (use, memory, temperature,
    power) and the busiest programs by CPU or by memory
  - a Wi-Fi and Bluetooth popup (switches, network list with password prompt,
    paired devices)
  - a **color picker**: a popup with a hex field (type `#c8a96a` and the swatch shows the
    color) and an eyedropper that picks any pixel on the screen and fills in its hex code
    (the eyedropper needs hyprpicker)
- **Lock screen**: the wallpaper, a big clock and a password field, checked with PAM like
  login does. Suspend locks first, so waking up asks for the password. See "Locking the
  screen" below.
- **Login screen** (optional, NixOS): the same look as the lock screen, for logging in instead of
  GDM or SDDM. See "Login screen" below.
- **Notifications**: the shell is the notification daemon, so apps (a browser,
  chat apps, `notify-send`) show up as cards in the top-right corner of the
  monitor you are using. They time out by themselves (critical ones stay until
  dismissed), pause while the mouse is over them, and a click dismisses them.
  A bell in the bar (with a badge for unread ones) opens the history, newest
  first, and has a **do not disturb** switch: while on, nothing pops up (critical
  ones still do) but everything is still recorded. Middle-click the bell to
  toggle do not disturb.
- **Messages from the shell itself**: when something you did fails, the shell
  says so in the same corner, as a red card: a wrong Wi-Fi password (the
  network's row says so too, and the password box opens again), a Bluetooth
  device that does not connect, a power action that is refused. They also go in
  the notification history and ignore do not disturb, because they answer what
  you just did.

## Screenshots

| Calendar and weather | Task manager |
|---|---|
| ![The calendar popup](docs/screenshots/calendar.jpg) | ![The task manager popup](docs/screenshots/task-manager.jpg) |
| **Wi-Fi and Bluetooth** | **Settings** |
| ![The Wi-Fi and Bluetooth popup](docs/screenshots/network.jpg) | ![The settings page](docs/screenshots/settings.jpg) |

The lock screen and the login screen share one look:

| Lock screen | Login screen |
|---|---|
| ![The lock screen](docs/screenshots/lock.jpg) | ![The login screen](docs/screenshots/login.jpg) |

Three of the nine themes (Gruvbox, Nord and the light Catppuccin Latte), picked in the settings page:

| Gruvbox | Nord | Catppuccin Latte |
|---|---|---|
| ![Gruvbox](docs/screenshots/theme-gruvbox.jpg) | ![Nord](docs/screenshots/theme-nord.jpg) | ![Catppuccin Latte](docs/screenshots/theme-latte.jpg) |

The pictures are taken in a virtual machine by `nix build .#screenshots`, so they show no
personal data. The weather is a made-up forecast served inside the machine, which has no
internet.

## Requirements

- Quickshell **0.3.0** or newer (developed and tested on 0.3 with Qt 6.11). The Nix package
  refuses an older one, so on a stable nixpkgs that is too old, build `sol-shell` from a
  newer nixpkgs
- **Hyprland**: workspaces and "log out" use it. Both the Lua config of Hyprland 0.55 and
  the older `hyprland.conf` work
- **NetworkManager** for Wi-Fi (the only network backend Quickshell supports)
- **BlueZ** for Bluetooth, **PipeWire** for volume
- a media player that supports MPRIS (Spotify, browsers, mpv, ...)
- the fonts **Material Design Icons** and **Symbols Nerd Font**
- optional: `lspci` (pciutils) for the name of an AMD graphics card, `nvidia-smi` for NVIDIA ones
- optional: `hyprpicker` for the color picker (the Nix package includes it)

### On NixOS (flake)

Add sol-shell as a flake input and import its module:

```nix
# flake.nix
inputs.sol-shell.url = "github:Tim-kieboom/sol-shell";

# in your NixOS configuration
imports = [ inputs.sol-shell.nixosModules.default ];
sol-shell.enable = true;
# optional: Wofi, Thunar and Dolphin, the programs whose colors the shell writes
sol-shell.themedApps.enable = true;
```

The module installs the `sol-shell` command, which is the shell itself, built from
your own nixpkgs (the Quickshell and Qt in your system), and everything around it:
`pciutils`, the two fonts and, optionally, the programs the shell themes. It also
switches on Hyprland, NetworkManager, Bluetooth and PipeWire (with `mkDefault`, so
settings you already have win). Then start the shell from Hyprland with
`exec-once = sol-shell`.

The same module works inside home-manager (`home-manager.users.<you>`) when you import
it by file (`imports = [ "${inputs.sol-shell}/quickshell.nix" ];`): it then installs the
packages and fonts for that user only, and the services belong to the system, so they
must already be enabled in your NixOS configuration.

Settings are kept in `~/.local/state/sol-shell/`, so updating the flake input does
not lose them.

Quickshell is wrapped so that it can read **webp** pictures: the Quickshell that
nixpkgs builds cannot (a webp wallpaper fails to load and the bundled one is shown
instead) because Qt keeps webp in a separate plugin, `qtimageformats`. On another
distribution, install that plugin too if you want webp wallpapers.

## Running it

```bash
sol-shell
```

starts the shell (put it in Hyprland's `exec-once`). `sol-shell ipc ...` and
`sol-shell log` talk to the running shell, wherever it is installed. To see warnings
and errors:

```bash
sol-shell log
```

From a checkout (not installed) run `bin/sol-shell`, or `quickshell -p <the folder>`.
Quickshell reloads the shell by itself whenever you save a file.

## Settings

The theme, the transparency and the wallpaper are chosen in the power menu: click the
NixOS icon, then **Settings**. They are saved to
`~/.local/state/sol-shell/settings.json`, outside this folder, so
they are never committed. The file looks like this and can be edited by hand:

```json
{
    "theme": "solliom",
    "backgroundOpacity": 0.8,
    "wallpaper": "",
    "doNotDisturb": false,
    "syncSystemColorScheme": false
}
```

- Themes: `solliom` (default), `catppuccin`, `gruvbox`, `nord`, `dracula`,
  `tokyonight`, `rosepine`, `everforest` and `catppuccin-latte` (a light theme).
- The picker lists the images in `~/Pictures/Wallpapers` (jpg, jpeg, png, webp; webp
  needs the Qt image plugin, see "On NixOS"). Create that folder yourself; the shell
  does not.
  An empty wallpaper (`""`) means the bundled painting, `wallpaper/Meisje_met_de_parel.jpg`
  (public domain, see `wallpaper/CREDITS.md`), which is also used if your own picture is
  missing or broken. It is shown whole on a dark background; your own pictures fill the
  screen and are cropped to fit. Pictures up to 1440 pixels high are supported; a
  bigger one works but takes more memory than it needs.
- Transparency (`backgroundOpacity`, 0.3 to 1.0 on the slider, default 0.8): how
  see-through the bar is. The popups are half as see-through (80% gives 90%), and the
  programs the shell themes (Wofi, Thunar, Zen) use the same value; they read it when
  they start. 1.0 is fully solid. See "Blurry backgrounds" for the blur.
- `doNotDisturb`: the do-not-disturb switch of the notification history.
- `syncSystemColorScheme` (off by default): see "Light or dark for everything else".
- A value that is out of range (a `backgroundOpacity` of 0 or 5) is pulled back into the
  slider's range. A settings file that cannot be read is reported in the log
  (`sol-shell log`) and the defaults are used.

## Locking the screen

The **Lock** and **Suspend** entries of the power menu, and these commands, lock the screen:

```bash
sol-shell ipc call lock lock       # lock now
sol-shell ipc call lock suspend    # lock, then suspend: waking up asks for the password
```

The lock is made by Hyprland itself (the `ext-session-lock` protocol), so nothing behind it
can be seen or clicked, and your password is checked with PAM through a service called
`sol-shell`. **The screen is only locked when `/etc/pam.d/sol-shell` exists**: a lock that could not be opened would leave you stuck, so
without it the shell shows a red card instead and, for Suspend, does not suspend.

On NixOS the module creates that service, but **only when it is imported in your NixOS
configuration**. Imported inside home-manager (`home.nix`) it cannot create system settings, so
add this line to your NixOS configuration (`configuration.nix`) and rebuild:

```nix
security.pam.services.sol-shell = { };
```

On another distribution, create that file yourself, for example (check it against your
distribution's own login configuration):

```
auth    include login
account include login
```

To lock after a while without input, run a program that watches for idle time and let it call
the command above (hypridle, with `lock_cmd = sol-shell ipc call lock lock`).

**If the shell stops while the screen is locked**, Hyprland keeps the screen locked and shows
a plain color: that is what makes the lock safe. Switch to a text console (Ctrl+Alt+F2),
log in, and start the shell again with `sol-shell`. If that does not bring back the lock
screen, end the Hyprland session from the console (`pkill Hyprland`) and log in again.

## Login screen

An optional login screen with the look of the lock screen: the wallpaper, a clock, who is
logging in, a password field, the session to start (Hyprland, ...) and restart and shut down
buttons. It is a [greetd](https://sr.ht/~kennylevinsen/greetd/) greeter, drawn by Quickshell
inside [cage](https://github.com/cage-kiosk/cage), and it is **NixOS only**. It is a separate
module, because a login screen is a system service (and the main module is also used from
home-manager):

```nix
# in your NixOS configuration (configuration.nix)
imports = [ inputs.sol-shell.nixosModules.greeter ];
sol-shell.greeter.enable = true;

# only one display manager can run: turn the current one off, for example
services.displayManager.gdm.enable = false;
```

- **Wallpaper:** the painting that ships with sol-shell. Use `sol-shell.greeter.wallpaper =
  ./picture.jpg;` for another one. It is not your wallpaper setting: nobody is logged in yet, so
  there is no home folder to read it from.
- **Passwords** are checked by greetd's own PAM service. With gnome-keyring enabled, the module
  turns on its unlocking at login, as the other display managers do.
- **Who and what:** every account with a user id of 1000 or more and a login shell is listed; the
  sessions are the installed `wayland-sessions`. The last user and session are remembered.
- **If it does not come up**, the greeter's output is in `/var/cache/sol-shell-greeter/greeter.log`.
  A text console (Ctrl+Alt+F2) always works, and you can switch the option off from there and
  rebuild.

Try it with a second way in at hand (a text console, or another display manager you can switch
back to) the first time.

## Weather

The temperature in the bar and the weather and 5-day forecast in the calendar popup come from
[Open-Meteo](https://open-meteo.com) (free, no account or key; the shell needs
internet for it). This is the only thing the shell fetches from the internet, and the
only thing it sends is the latitude and longitude from the file below, to
`api.open-meteo.com`. Notification pictures given as `http(s)` addresses are never
loaded. The place is read from a small file that you write yourself (nothing creates it):

```json
{ "latitude": 51.9225, "longitude": 4.47917, "locationName": "Rotterdam" }
```

at `~/.config/quickshell/weather-location.json`. The file is watched: change the
place and the weather follows within seconds, without a restart. It is refreshed
every 15 minutes. Without the file (or with a broken one) the bar simply shows no
temperature and the popup says where to put it. If a refresh fails the last numbers
stay, the icon dims, and the popup says they may be out of date. Temperatures are
in degrees Celsius.

`sol-shell ipc call weather summary` prints what the
shell currently knows, and `call weather refresh` fetches again at once.

## Controlling it from outside

The shell listens for commands, so a Hyprland keybind can drive it. For example,
to toggle do not disturb (the other commands are `clear`, `count`, `unread`,
`list` and `dnd`; `sol-shell ipc show` lists everything. `sysmon summary`
prints the task manager numbers as text; it exists once the popup has been opened,
and shows "inactive" while the popup is closed):

```bash
sol-shell ipc call notifications toggleDoNotDisturb
```

The color picker has a command too, for a keybind: `sol-shell ipc call picker pick` starts
the eyedropper (the popup opens on the monitor you are using, with the color in its field),
and `call picker last` prints the last color picked.

Scripts can show a message in the shell too (a red card for `error`, a plain one
for `info`), and `count` says how many are on screen:

```bash
sol-shell ipc call messages error "Backup failed" "The disk is full"
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
| Thunar (GTK3 programs) | `export/gtk.css.tpl` | `~/.local/state/theme/gtk.css` | one link, see below |
| Zen browser | `export/zen-userChrome.css.tpl`, `zen-userContent.css.tpl`, `zen-user.js.tpl` | `zen-*` in `~/.local/state/theme/` | `export/zen-setup.sh`, see below |

Write the files again by hand with
`sol-shell ipc call themeExport run`.

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

**Thunar** and other GTK3 programs read `~/.config/gtk-3.0/gtk.css`. One link,
made once:

```bash
ln -s ~/.local/state/theme/gtk.css ~/.config/gtk-3.0/gtk.css
```

GTK's built-in Adwaita theme ignores redefined named colors (measured), so the
template colors each kind of widget with an explicit rule. A program picks the
theme up when it starts: restart Thunar (`thunar -q`) after switching theme.
Folder icons stay blue: they belong to the icon theme.

**Zen browser** reads three files from its profile. Run the setup script once,
with Zen closed:

```bash
bash export/zen-setup.sh   # from a checkout
# installed with Nix: the same script inside the package
bash "$(dirname "$(readlink -f "$(command -v sol-shell)")")/../share/sol-shell/export/zen-setup.sh"
```

It finds the default profile in `~/.config/zen/profiles.ini` and links:

| Profile file | Generated from | What it does |
|---|---|---|
| `chrome/userChrome.css` | `zen-userChrome.css.tpl` | colors Zen's own interface |
| `chrome/userContent.css` | `zen-userContent.css.tpl` | colors Zen's own pages (settings, `about:`) |
| `user.js` | `zen-user.js.tpl` | turns on custom stylesheets (off by default), and sets the dark/light that websites and the toolbar follow |

Websites keep their own design, but they are told the theme is dark or light
(`prefers-color-scheme`), so sites that support both follow it. Whether a theme
counts as dark or light is judged from its background color.

The script never overwrites a real file: if your `user.js` has your own
settings in it, it leaves it alone and says so (then move it away and run the
script again, or copy the lines from `zen-user.js.tpl` into it yourself, though
then the dark/light will not follow the theme). It refuses to run while the
profile is open. Zen reads these files only at startup, so restart it after
switching theme.

### Light or dark for everything else

Programs whose colors the shell cannot change, such as Claude Desktop (its colors come
from the website) and other Electron or GTK4 programs, can still follow the theme's
light or dark side. This is **off by default**, because it changes your desktop-wide
preference: switch on "Light or dark for other apps" in the settings page (or set
`syncSystemColorScheme` to `true`). The exporter then writes `prefer-dark` or
`prefer-light` to `/org/gnome/desktop/interface/color-scheme` (with `dconf`) every time
the theme changes, and the desktop settings portal passes that on. Switching it off
leaves the last value in place. The NixOS module installs `dconf` and enables
`programs.dconf`. Claude Desktop must be on its default
`userThemeMode: "system"`; restart it after switching if it does not follow at once.
This is the one setting here that is not a file under `~/.local/state/theme`.

### Blurry backgrounds

Wofi, Thunar and Zen have see-through backgrounds. How see-through is the
`backgroundOpacity` setting (the Transparency slider in the settings page, or `settings.json`; default 0.8; 1.0
turns it off). The blur itself is done by Hyprland, which blurs whatever shows
through a translucent window. Two things are needed in `~/.config/hypr/hyprland.lua`:

- blur on and strong enough to see: `decoration.blur` with `enabled = true`,
  for example `size = 8, passes = 3` (the default `size 3, passes 1` is barely visible);
- Wofi is a layer surface, so it needs its own rule (windows like Thunar and Zen
  do not):

```lua
hl.layer_rule({
    name         = "blur-wofi",
    match        = { namespace = "^wofi$" },
    blur         = true,
    ignore_alpha = 0.1,
})
```

In Zen only the sidebar and toolbar are see-through; the page itself is not, as
websites paint their own background. Zen needs its window transparency switched
on, which the generated `user.js` does (`zen.widget.linux.transparency`).
In templates, `{{backgroundAlpha}}` (and `{{windowAlpha}}`, ...) is a color with
that opacity: `rgba(17, 17, 27, 0.80)`.

## How it fits together

```
shell.qml            entry point: a wallpaper and a bar on every monitor
export/              templates and the exporter that themes other programs (wofi, dolphin, thunar, zen)
wallpaper/           the wallpaper window and the bundled default picture
flake.nix            the flake: the package, the NixOS module and the VM test
package.nix          builds the shell into the Nix store (the `sol-shell` command)
quickshell.nix       NixOS / home-manager module with everything the shell needs
bin/sol-shell        the command line: start, `ipc` and `log`
tests/vm.nix         NixOS VM test: fresh user, Hyprland, the shell from the flake
statusbar/           the bar and everything in it
  components/          the bar's parts (media, clock, workspaces, popups, ...)
    indicators/        CPU, memory, volume and weather indicators
    calendar/          the calendar popup of the clock
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
- The calendar always starts the week on Monday (ISO week numbers); the weather
  is in Celsius and the weather descriptions are in English.
- Only the first Wi-Fi device is handled; wired connections are not shown.
- The task manager shows NVIDIA graphics cards (through `nvidia-smi`) and AMD ones
  (through `/sys`); Intel ones are not shown yet.
- Notifications: no action buttons yet, and the history lives in memory only (it
  is empty again after the shell restarts). Only one program can be the
  notification daemon, so do not run mako, dunst or similar next to this shell.
- Failure messages depend on what NetworkManager and BlueZ report. A wrong Wi-Fi
  password is recognized from NetworkManager's reasons (no secrets, authentication
  timeout, client failure); a Bluetooth device that never answers is reported
  after 20 seconds. A Wi-Fi network that the shell saved from a typed password
  is forgotten again if that password fails, so you are asked once more.
- Typing a Wi-Fi password relies on the popup's focus grab (`grabFocus` in
  `BarPopup`) to give it the keyboard. If typing does nothing on your setup,
  look there first.
- Quickshell 0.3.0 can crash in its live reload when many files change at the
  same moment (for example a script editing dozens of files). It restarts
  itself, so this only matters while developing.

## Tests and license

`nix build .#checks.x86_64-linux.vm -L` boots a NixOS machine with a fresh user and
Hyprland, starts the shell from the flake and checks that it stays up with no errors
in its log, answers `sol-shell ipc`, saves settings, and draws the clock (read back
with OCR). It cannot judge how the bar looks.

`nix build .#checks.x86_64-linux.greeter -L` boots a machine with the login screen, types a wrong
password (refused), then the right one, and checks that the user's Hyprland session starts.

The code is under the MIT license (`LICENSE`). The default wallpaper is a public
domain painting with its own credit in `wallpaper/CREDITS.md`.
