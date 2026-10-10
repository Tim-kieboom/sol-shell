# The login screen on a fresh NixOS machine: greetd starts cage, which shows the greeter.
# The test types a wrong password (refused: no session starts), then the right one, and
# checks that alice's Hyprland session starts.
#
#     nix build .#checks.x86_64-linux.greeter -L
{ pkgs, self }:

pkgs.testers.runNixOSTest {
  name = "sol-shell-greeter";

  nodes.machine = { pkgs, ... }: {
    imports = [ self.nixosModules.greeter ];
    sol-shell.greeter.enable = true;

    # the session to log in to
    programs.hyprland.enable = true;

    users.users.alice = {
      isNormalUser = true;
      uid = 1000;
      # the test types this one (a test machine only)
      password = "sol-shell-test-password";
    };

    # to type on the screen
    environment.systemPackages = [ pkgs.ydotool ];
    programs.ydotool.enable = true;

    # a machine without a graphics card: draw in software
    hardware.graphics.enable = true;
    systemd.services.greetd.environment = {
      WLR_RENDERER_ALLOW_SOFTWARE = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
    };

    virtualisation = {
      memorySize = 4096;
      cores = 4;
      resolution = { x = 1280; y = 800; };
      qemu.options = [ "-vga none" "-device virtio-vga" ];
    };
  };

  testScript = ''
    typing = "env YDOTOOL_SOCKET=/run/ydotoold/socket "

    machine.wait_for_unit("greetd.service")
    machine.wait_until_succeeds("pgrep -f sol-shell-greeter", timeout=120)
    # the screen is drawn; give the user and session lists a moment to load
    machine.sleep(10)
    machine.screenshot("greeter")

    # what the greeter said to greetd (it logs there; nothing else shows a login screen's
    # output). The password is never in it.
    greeter_log = "/var/cache/sol-shell-greeter/greeter.log"

    with subtest("a wrong password does not start a session"):
        machine.succeed(typing + "ydotool type wrong-password")
        machine.succeed(typing + "ydotool key 28:1 28:0")
        # PAM answers a wrong password with an authentication error, after a short delay
        machine.wait_until_succeeds("grep -q auth_error " + greeter_log, timeout=30)
        machine.sleep(2)
        machine.fail("pgrep -u alice Hyprland")
        machine.screenshot("greeter-wrong")

    with subtest("the right password starts the session"):
        machine.succeed(typing + "ydotool type sol-shell-test-password")
        machine.succeed(typing + "ydotool key 28:1 28:0")
        machine.wait_until_succeeds("pgrep -u alice Hyprland", timeout=120)
        machine.succeed("grep -q start_session " + greeter_log)
  '';
}
