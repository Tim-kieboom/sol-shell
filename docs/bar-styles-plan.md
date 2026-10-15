# Bar styles: implementation plan

Goal: switch the status bar between the current minimalist look and an Ashell-style look
(floating islands), live, from the settings. This plan comes out of a design interview;
the decisions below are settled unless marked **open**.

## Decisions

| Area | Decision |
|---|---|
| Structure | One data-driven bar. A style is a descriptor; one renderer builds the bar from it. Not two bar files. |
| Atoms | Bundled components are split into real atoms. The style lists atoms by name. |
| Popups | Every atom owns its own popup. The style supplies the popup edge and gap. |
| Click-through (slice 1) | Weather opens the calendar. Memory opens the task manager. No new weather or memory popups. |
| Sizing | The style owns pill height, padding, radius and spacing. Per-atom overrides are allowed (minimalist needs exact 18, 20, 26 and 30). |
| Position | `top` or `bottom`, supplied by the style. `BarPopup` flips its edges and gravity from it. |
| Opacity | Per surface (bar, islands, popups) within each style, with a per-style default and floor. The islands bar window is transparent. |
| Input | The bar window has an input mask over the atoms' bounds, so the gaps between islands let clicks through. |
| Switching | Applies immediately and rebuilds every bar. |
| Settings | Moves out of the bar into a window owned at `ShellRoot` level. It is a required atom in every style and is reachable through IPC. |
| Bad descriptor | Fall back to minimalist, on boot and on switching, with a log warning. The saved `barStyle` is never overwritten. Minimalist is built in and validated by the test run. |
| Verification | Cropped screenshots of a throwaway window, with live text masked. Each atom reports its own `textRect`. Plus a manual click checklist. |
| Islands values | First guess, to be tuned by the user after seeing it: bar padding `Xxs`, island radius `Lg`, gap about 4px, island height about 26px, fill from the theme's surface colour. |

## Today's code (what changes)

- `statusbar/Statusbar.qml`: one hardcoded `RowLayout`, height 30, opacity from
  `Settings.backgroundOpacity`, `Spacer` sizes 1, 5, 2, 10.
- Bundled components: `SystemIndicators` (CPU and memory, one popup), `Connectivity`
  (wifi and bluetooth, one popup), `ClockWeather` (one popup), `PowerMenu` (power menu
  and settings page in one popup).
- `statusbar/components/BarPopup.qml`: top-only. It hardcodes `Edges.Bottom`, the
  gravity and `anchor.margins.top: 6`.
- `singletons/Settings.qml`: one saved `backgroundOpacity` and one `minBackgroundOpacity`.
- `viewerCount` pattern: `NetworkService` and `SystemMonitorService` count open popups to
  decide whether to poll. Each popup adds one on open and removes one on close. This must
  keep pairing once atoms are split.

## Slice 1: atoms and a descriptor for minimalist

Gate: cropped screenshot parity, plus the click checklist.

1. **Capture the baseline first.** Screenshot the current bar before touching anything
   (see the test procedure below). Without the baseline, the gate can't be passed.
2. **Split the atoms.** New or changed files in `statusbar/components/`:
   - `Wifi.qml` and `Bluetooth.qml` from `Connectivity.qml`. Wifi owns the network list
     popup and bluetooth owns the device list popup, and each keeps its own `viewerCount`
     handling. Bluetooth needs its own `BluetoothService` viewer logic if the combined
     popup was feeding it. **Check `BluetoothService` first.**
   - `Cpu.qml` and `Memory.qml` from `SystemIndicators.qml`. Cpu owns the task manager
     popup. Memory is click-through and gets its own `BarPopup` with the same
     `TaskManager {}` content (two instances, one open at a time because of the focus
     grab). `SystemMonitorService.viewerCount` still pairs, since each popup counts
     itself.
   - `Clock.qml` and `Weather.qml` from `ClockWeather.qml`. Clock owns the calendar
     popup. Weather gets its own `BarPopup` with `CalendarPopup {}`.
   - `PowerMenu.qml` keeps only the power actions. The settings page is removed here and
     comes back in slice 2.
   - Delete the bundles once nothing uses them.
3. **Add the descriptor type and the minimalist descriptor.** New `statusbar/styles/`
   folder: `MinimalStyle.qml` (a plain QtObject) holding `position`, `popupGap`,
   `surface`, `atoms: { left: [...], center: [...], right: [...] }`, `groups`,
   `pill: { height, padding, radius, spacing }`, `overrides: { atomName: { height, ... } }`
   and `opacity: { bar, islands, popups, min }`.
4. **Add the renderer.** `statusbar/BarRenderer.qml` builds the left, centre and right
   sections from the descriptor. An atom registry (`statusbar/AtomRegistry.qml`) maps
   names to components. Atoms read size and spacing from the current style through a
   `BarStyle` singleton, not from hardcoded numbers.
5. **Replace the hardcoded numbers.** Remove the `implicitHeight` values (30, 26, 18, 20)
   and the `Spacer` values from the atoms. `MinimalStyle` expresses the same numbers as
   pill metrics plus per-atom overrides.
6. **Add `textRect` and `bounds`.** Each atom exposes `readonly property rect textRect`
   (null for atoms with no live text) and uses its own `bounds`. Add one optional test
   property, no logic.
7. **Run the gate** (test procedure below). Fix drift until the cropped diff is clean.

## Slice 2: settings out of the bar

1. New `settings/SettingsWindow.qml`, owned at `ShellRoot` level in `shell.qml` like
   `SessionLock` and `NotificationPopups`. It reuses `statusbar/components/settings/SettingsPage.qml`.
2. New `singletons/SettingsService.qml` with `open()`, `close()` and `toggle()`, and an
   `IpcHandler { target: "settings" }` (same pattern as `ShellMessages`). Example:
   `sol-shell ipc call settings open`.
3. Add a `Settings` atom (an icon button) that calls `SettingsService.toggle()`. The
   renderer refuses a descriptor that lacks it (see slice 4).
4. Remove the settings page and the `page` property from `PowerMenu.qml`.
5. Click checklist: the settings window opens from the atom and from IPC, and survives a
   bar rebuild.

## Slice 3: position and popup gap from the style

1. `BarPopup.qml` reads `BarStyle.position` and `BarStyle.popupGap`. For `top` it uses
   today's edges and gravity. For `bottom` it flips them to grow upward, and the gap goes
   on the bottom margin.
2. `Statusbar.qml` anchors to the top or bottom edge from the style, and the exclusive
   zone covers the bar height plus its outer margin.
3. Add a throwaway bottom-position copy of the minimalist descriptor to prove the flip
   (not shipped). Check that popups open upward and stay on screen at both ends.

## Slice 4: validation and fallback

1. `statusbar/StyleLoader.qml` validates a descriptor before use: every atom name exists,
   the settings atom is present, `position` is `top` or `bottom`, the opacity floor is
   not above its default.
2. On any failure: log a warning, use minimalist, show a notice in the settings window,
   and leave the saved `barStyle` untouched.
3. The same validation runs for the saved style on boot.
4. Test: a deliberately bad descriptor falls back on boot and on switch, and the saved
   value stays unchanged.

## Slice 5: the islands style

1. `statusbar/styles/IslandsStyle.qml` with the guessed values above, and the left,
   centre and right groups. Start from Ashell's default layout (workspaces left, title
   centre, a status group right) and map it to your atoms.
2. Renderer support for groups: each group becomes one island `Rectangle` (fill, radius,
   padding, gap). The bar window itself is transparent.
3. **Input mask.** Set `mask: Region` on the bar window from the islands' bounds. It must
   follow the layout as atoms appear and disappear.
4. **Opacity.** In `singletons/Settings.qml` replace the single saved `backgroundOpacity`
   with `opacityByStyle`. On load, migrate an existing `backgroundOpacity` into
   `opacityByStyle.minimal` once, and give islands their own default. Make the floor
   per-style. A pending slider draft is discarded when the style changes.
5. Add a `barStyle` property to the saved settings and a style picker in the settings
   page, in the style of the theme chips. It applies immediately and rebuilds every bar.
6. Tuning pass by the user after the first render.

## Test procedure

- **Throwaway window only.** Per the screenshot-safety note: capture a test window and
  verify the pid before running `grim`. Never capture the real desktop.
- Capture the bar region, then black out each atom's `textRect` in both images, then diff.
  Flag any difference in pixels outside the masks.
- Atom width depends on text (`10:59` vs `11:00`), so the masks use the atom's bounds for
  layout comparison and the `textRect` only for blanking pixels.
- **Manual click checklist** (a screenshot diff will not catch these):
  - Each popup opens from its own atom and closes on a click outside.
  - Weather opens the calendar and memory opens the task manager.
  - Wifi opens only the wifi list and bluetooth opens only the device list.
  - Power opens only the power actions.
  - Settings opens from the atom and from IPC, and survives a style switch.
  - With two popups in sequence, `viewerCount` returns to 0 (check that the network
    scan and `/proc` polling stop).

## Risks

- Slice 1 changes minimalist's behaviour (split popups, click-through) while the gate only
  checks geometry. The click checklist is the safeguard.
- `viewerCount` pairing can break when two atoms own popups over the same service.
- Atom widths change when live text changes, which can make masks flaky if they use text
  bounds.
- The islands values are a guess, so keep them in the descriptor only.

## Open

- `BluetoothService` may need its own viewer counting. Check before splitting.
- Per-atom override shape in the descriptor is not final. Start with `height`, `padding`
  and `spacing`, and add more only when an atom needs them.
