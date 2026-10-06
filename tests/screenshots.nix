# Screenshots for the README, taken in the same VM as the test (tests/machine.nix), so
# nothing personal is on screen:
#
#     nix build .#screenshots -L
#     ls result/
#
# The machine has no network, so the weather says where to put its location file, and no
# audio, Wi-Fi or Bluetooth hardware, so those popups are mostly empty. The pointer is
# placed with `hyprctl dispatch movecursor` (Hyprland's classic .conf mode, which the VM
# runs) and clicked with ydotool.
{ pkgs, self }:

pkgs.testers.runNixOSTest {
  name = "sol-shell-screenshots";

  nodes.machine = { pkgs, ... }: {
    imports = [ (import ./machine.nix { inherit self; }) ];
    environment.systemPackages = [ pkgs.libnotify pkgs.ydotool ];
    programs.ydotool.enable = true;
    users.users.alice.extraGroups = [ "ydotool" ];
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")
    machine.wait_until_succeeds("pgrep -u alice -f quickshell", timeout=120)
    machine.sleep(8)
    signature = machine.succeed("ls /run/user/1000/hypr").strip()

    def as_alice(command):
        return machine.succeed(
            "runuser -u alice -- env XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1"
            " DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus"
            " YDOTOOL_SOCKET=/run/ydotoold/socket HYPRLAND_INSTANCE_SIGNATURE=" + signature + " " + command
        )

    def pause(seconds):
        machine.execute("sleep %s" % seconds)

    def click(x, y):
        as_alice("hyprctl dispatch movecursor %d %d" % (x, y))
        pause(0.5)
        as_alice("ydotool click 0xC0")
        pause(1.5)

    # take the picture with the pointer out of the way, in a corner
    def shot(name):
        as_alice("hyprctl dispatch movecursor 1279 799")
        pause(1)
        machine.screenshot(name)

    # Hyprland's own banners (config format, start-hyprland) are not part of the shell
    as_alice("hyprctl dismissnotify")

    shot("01-desktop")

    click(606, 15)
    shot("02-calendar")
    click(606, 15)

    click(1040, 15)
    shot("03-task-manager")
    click(1040, 15)

    click(1184, 15)
    shot("04-network")
    click(1184, 15)

    as_alice("notify-send -a Mail -u normal 'New message' 'Lunch tomorrow at noon?'")
    as_alice("notify-send -a Backup -u critical 'Backup failed' 'The disk is full'")
    as_alice("notify-send -a Music -u low 'Now playing' 'Vermeer, Girl with a Pearl Earring (the album)'")
    pause(2)
    shot("05-notifications")
    # the normal and low ones time out by themselves; a critical one stays until its x is clicked
    pause(8)
    click(1247, 58)

    click(34, 15)
    shot("06-power-menu")
    click(83, 57)
    shot("07-settings")

    # the theme chips in the settings page: (x, y) of each one
    for name, x, y in [("gruvbox", 284, 133), ("nord", 67, 195), ("tokyonight", 284, 195), ("catppuccin-latte", 284, 257)]:
        click(x, y)
        shot("08-settings-" + name)
  '';
}
