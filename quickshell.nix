# Everything sol-shell needs, as a NixOS module.
#
# Use it from your NixOS configuration (configuration.nix, or a module of your flake):
#
#     imports = [ /home/you/.config/quickshell/sol-shell/quickshell.nix ];
#     sol-shell.enable = true;
#
# The wallpaper, bar and popups themselves are QML files that Quickshell reads straight
# from the sol-shell folder; this file only provides what that QML needs around it:
# Quickshell, the programs it starts, the fonts, and the system services it talks to.
# Start the shell from Hyprland with:
#
#     quickshell -p ~/.config/quickshell/sol-shell
{ config, lib, pkgs, ... }:

let
  cfg = config.sol-shell;

  # Quickshell as nixpkgs builds it can read gif, ico, jpeg, png and svg pictures, but
  # not webp (checked: the picture fails with "Unsupported image format"), which the
  # wallpaper picker lists. Qt keeps webp in a separate plugin, so Quickshell is wrapped
  # to find it. The plugin has to come from the same Qt as Quickshell itself, which is
  # why it is taken from the same `pkgs`.
  quickshell = pkgs.symlinkJoin {
    name = "quickshell-sol-shell-${pkgs.quickshell.version}";
    paths = [ pkgs.quickshell ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      # `quickshell` runs the shell, `qs` is the same program under its short name
      # (used for `qs ipc` and `qs log`)
      for program in quickshell qs; do
        wrapProgram $out/bin/$program \
          --prefix QT_PLUGIN_PATH : ${pkgs.qt6.qtimageformats}/${pkgs.qt6.qtbase.qtPluginPrefix}
      done
    '';
    meta.mainProgram = "quickshell";
  };
in
{
  options.sol-shell = {
    enable = lib.mkEnableOption "the packages and services that sol-shell needs";

    themedApps.enable = lib.mkEnableOption ''
      the programs whose colors sol-shell writes to ~/.local/state/theme (Wofi, Thunar
      and Dolphin). Without them the shell works the same, the theme files are just
      not used by anything. Zen browser is not in nixpkgs, so it is not included here
    '';
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      quickshell

      # `lspci`: the name of an AMD graphics card in the task manager popup.
      # (Everything else the shell starts (sh, cat, find, mkdir, systemctl, hyprctl) is
      # already on a NixOS system with Hyprland. `nvidia-smi` for NVIDIA cards comes with
      # the NVIDIA driver, and the task manager simply skips what is not there.)
      pkgs.pciutils

      # icons by name: the pictures in notifications, and in the programs themed below
      pkgs.adwaita-icon-theme
    ] ++ lib.optionals cfg.themedApps.enable [
      pkgs.wofi
      pkgs.thunar
      pkgs.kdePackages.dolphin
    ];

    fonts.packages = [
      # the icons (power, wifi, bell, weather, ...): "Material Design Icons"
      pkgs.material-design-icons
      # the bar's text font name; it holds only symbols, ordinary letters come from the
      # system's fallback font: "Symbols Nerd Font"
      pkgs.nerd-fonts.symbols-only
    ];

    # The window manager: workspaces and "log out" use hyprctl
    programs.hyprland.enable = lib.mkDefault true;

    # What the popups in the bar talk to. Quickshell has no other Wi-Fi backend than
    # NetworkManager. `mkDefault` means that settings you already have win.
    networking.networkmanager.enable = lib.mkDefault true;
    hardware.bluetooth.enable = lib.mkDefault true;
    services.pipewire = {
      enable = lib.mkDefault true;
      wireplumber.enable = lib.mkDefault true;
    };
  };
}
