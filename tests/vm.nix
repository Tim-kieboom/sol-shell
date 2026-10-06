# A fresh NixOS machine with a fresh user, the way a stranger who adds sol-shell as a
# flake input would have it. The test fails the build when the shell does not come up.
#
#     nix build .#checks.x86_64-linux.vm -L
#
# The machine has no GPU, no Wi-Fi, no Bluetooth and no battery: Hyprland draws in
# software, and the popups for the missing hardware are simply empty. So the test
# checks that the shell starts, stays up, logs no errors, answers `sol-shell ipc` and
# draws text on the bar. It cannot judge how the bar looks.
{ pkgs, self }:

pkgs.testers.runNixOSTest {
  name = "sol-shell";

  # lets the script read the screen: `machine.wait_for_text(...)`
  enableOCR = true;

  nodes.machine = { lib, ... }: {
    imports = [ self.nixosModules.default ];
    sol-shell.enable = true;

    users.users.alice = {
      isNormalUser = true;
      uid = 1000;
    };

    # alice logs in on the first console and that login starts Hyprland, which starts
    # the shell, which is what a first-time user's session boils down to
    services.getty.autologinUser = "alice";
    programs.bash.loginShellInit = ''
      if [ "$(tty)" = /dev/tty1 ]; then
        exec Hyprland --config /etc/sol-shell-test-hyprland.conf
      fi
    '';
    environment.etc."sol-shell-test-hyprland.conf".text = ''
      exec-once = sol-shell
      misc {
        disable_hyprland_logo = true
        disable_splash_rendering = true
      }
    '';

    # Hyprland on a machine without a graphics card: draw in software
    environment.sessionVariables = {
      WLR_RENDERER_ALLOW_SOFTWARE = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
    };
    hardware.graphics.enable = true;

    virtualisation = {
      memorySize = 4096;
      cores = 4;
      resolution = { x = 1280; y = 800; };
      qemu.options = [ "-vga none" "-device virtio-vga" ];
    };
  };

  testScript = ''
    def as_alice(command):
        return machine.succeed(
            "runuser -u alice -- env XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 " + command
        )

    machine.wait_for_unit("multi-user.target")
    machine.wait_until_succeeds("pgrep -u alice Hyprland", timeout=120)
    machine.wait_until_succeeds("pgrep -u alice -f quickshell", timeout=120)

    with subtest("the shell stays up and its log has no errors"):
        machine.sleep(20)
        machine.succeed("pgrep -u alice -f quickshell")
        log = as_alice("sol-shell log")
        print(log)
        assert "ERROR" not in log, "the shell logged errors, see above"

    with subtest("sol-shell ipc reaches the running shell"):
        out = as_alice("sol-shell ipc call themeExport run")
        assert out.strip().endswith("/.local/state/theme"), out
        machine.wait_until_succeeds("test -s /home/alice/.local/state/theme/wofi.css")
        machine.wait_until_succeeds("test -s /home/alice/.local/state/theme/gtk.css")

        # a setting changed through ipc is saved in the fixed settings folder
        as_alice("sol-shell ipc call notifications toggleDoNotDisturb")
        machine.wait_until_succeeds(
            "grep -q '\"doNotDisturb\": true' /home/alice/.local/state/sol-shell/settings.json"
        )

    with subtest("the bar draws text"):
        machine.screenshot("bar")
        # the clock reads like "20:31 • Tuesday 6-Oct-2026"
        machine.wait_for_text(r"\d\d:\d\d", timeout=60)
  '';
}
