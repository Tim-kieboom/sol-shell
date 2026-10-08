# The machine shared by the tests: a fresh NixOS with a fresh user `alice`, who logs in
# on the first console, which starts Hyprland, which starts sol-shell. The machine has
# no GPU, no Wi-Fi, no Bluetooth and no battery: Hyprland draws in software, and the
# popups for the missing hardware are simply empty.
{ self }:

{ lib, pkgs, ... }: {
  imports = [ self.nixosModules.default ];
  sol-shell.enable = true;

  # to click on the screen (ydotool), and to send a notification (notify-send)
  environment.systemPackages = [ pkgs.ydotool pkgs.libnotify ];
  programs.ydotool.enable = true;

  users.users.alice = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "ydotool" ];
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
}
