# sol-shell v0.1.0 todo

Goal: a GitHub release that NixOS users add as a flake input, tested in a fresh-user VM.

## Done (uncommitted)

- [x] Default wallpaper is Vermeer's *Girl with a Pearl Earring*, downscaled to 1230x1440 (475 KB), shown whole with a matching dark background (`#030212`). Your own pictures still fill and crop.
- [x] Saved wallpaper default is `""` (use the shipped one), so a fresh user does not get an image error for a missing `~/Pictures/Wallpapers/wallpaper_1.jpg`.
- [x] `sunsetWallpaper.jpg` removed.

## Before the tag

1. [x] `flake.nix` + `package.nix`
   - `packages.default`: the QML copied into the store, plus the wrapped `quickshell` (webp plugin) from `quickshell.nix`.
   - `nixosModules.default`: reuses `quickshell.nix` and also installs the package.
2. [x] Launcher script `bin/sol-shell`
   - `sol-shell` runs `quickshell -p <store path>`.
   - `sol-shell ipc ...` runs `qs ipc -p <store path> ...`, so keybinds do not need a path.
3. [x] Settings path that does not depend on where the shell lives
   - `Quickshell.statePath("settings.json")` is per shell path, so a store path would reset wallpaper and transparency on every `nix flake update`.
   - Now `~/.local/state/sol-shell/settings.json`. No migration: the old `by-shell/<id>/settings.json` is not read, so settings reset once.
4. [ ] `nixosTest` in `flake.nix` that fails the build
   - Fresh user, headless Hyprland, software rendering.
   - Assertion 1: `quickshell` is still alive about 20 s after start and its log has no QML errors.
   - Assertion 2: `sol-shell ipc ... call weather summary` / `themeExport run` returns output, and the theme files appear in `~/.local/state/theme`.
   - Assertion 3: a screenshot with OCR finds the clock text on the bar.
   - Fallback if 3 is flaky in the VM: ship with 1 and 2 and do not hold the release.
5. [ ] `LICENSE` (MIT) and a credit line for the painting
   - Wikimedia Commons file name and URL, public domain, downscaled to 1440 high.
   - Check that the Commons page carries a public-domain tag for faithful reproductions.
6. [ ] README
   - Install section: flake input instead of `imports = [ /home/you/... ]`.
   - Keybinds use `sol-shell ipc ...` instead of `qs ipc -p ~/.config/...`.
   - Say that wallpapers up to 1440 high are supported.
7. [ ] Look at the new default wallpaper on a real monitor for a visible seam at the edge of the painting.

## Not in v0.1.0

- `homeModules` export (the module already works in both; it just is not exported under that name)
- Zen theming
- The rest of the README rewrite
- Anything not on the list above

## Known risks

- OCR on a software-rendered screenshot may be flaky. See the fallback in item 4.
- The wallpaper change has not been run in the real shell yet.
