# Everything sol-shell needs, as a module for NixOS OR home-manager.
#
# Import it in either place and switch it on:
#
#     imports = [ inputs.sol-shell.nixosModules.default ];
#     sol-shell.enable = true;
#
#   - in your NixOS configuration it installs the packages system-wide, and also
#     switches on the services the popups talk to (see `nixosOnly` below);
#   - in a home-manager configuration (home-manager.users.<you>) it installs the
#     packages and fonts for that user. The services cannot be switched on from there:
#     they belong to the system, so NetworkManager, Bluetooth, PipeWire and Hyprland
#     must already be enabled in your NixOS configuration.
#
# This installs the `sol-shell` command (the shell itself, built from package.nix with
# your own nixpkgs) and what the QML needs around it. Start the shell from Hyprland with:
#
#     sol-shell
#
# and bind keys with `sol-shell ipc call ...`.
{ config, lib, pkgs, options, ... }:

let
  cfg = config.sol-shell;

  # Which kind of module system is this? Each has options the other does not have, and
  # defining an option that does not exist is an error ("The option ... does not
  # exist") even inside `mkIf false`, so the right half of the settings is picked
  # below with a plain `if`, which leaves the other half out completely.
  isNixOS = options ? environment;
  isHomeManager = options ? home;

  packages = [
    # the `sol-shell` command, and Quickshell wrapped for webp pictures (`qs`, `quickshell`)
    cfg.package
    cfg.package.quickshell

    # `lspci`: the name of an AMD graphics card in the task manager popup.
    # (Everything else the shell starts (sh, cat, find, mkdir, systemctl, hyprctl) is
    # already on a NixOS system with Hyprland. `nvidia-smi` for NVIDIA cards comes with
    # the NVIDIA driver, and the task manager simply skips what is not there.)
    pkgs.pciutils

    # the color picker in the bar: `hyprpicker` picks the pixel. The `sol-shell` command
    # also has it on its own PATH; this is for running the shell from a checkout.
    pkgs.hyprpicker

    # `dconf`: writes the light or dark preference for apps the shell cannot color. Only
    # used when "Light or dark for other apps" is switched on in the settings page.
    pkgs.dconf

    # icons by name: the pictures in notifications, and in the programs themed below
    pkgs.adwaita-icon-theme
  ] ++ lib.optionals cfg.themedApps.enable [
    pkgs.wofi
    pkgs.thunar
    pkgs.kdePackages.dolphin
  ];

  fonts = [
    # the icons (power, wifi, bell, weather, ...): "Material Design Icons"
    pkgs.material-design-icons
    # the bar's text font name; it holds only symbols, ordinary letters come from the
    # system's fallback font: "Symbols Nerd Font"
    pkgs.nerd-fonts.symbols-only
  ];

  # What only a NixOS configuration can switch on. `mkDefault` means that settings you
  # already have win.
  nixosOnly = {
    environment.systemPackages = packages;
    fonts.packages = fonts;

    # The lock screen checks your password with PAM, the same way login does, through a
    # service of its own. Without it the screen would not be locked at all.
    security.pam.services.sol-shell = lib.mkDefault { };

    # The window manager: workspaces and "log out" use hyprctl
    programs.hyprland.enable = lib.mkDefault true;

    # the settings database behind `dconf` (see above)
    programs.dconf.enable = lib.mkDefault true;

    # What the popups in the bar talk to. Quickshell has no other Wi-Fi backend than
    # NetworkManager.
    networking.networkmanager.enable = lib.mkDefault true;
    hardware.bluetooth.enable = lib.mkDefault true;
    services.pipewire = {
      enable = lib.mkDefault true;
      wireplumber.enable = lib.mkDefault true;
    };
  };

  # What home-manager offers instead: packages in the user's profile. Fonts there are
  # packages too, and fontconfig has to be told to look in the profile for them.
  homeManagerOnly = {
    home.packages = packages ++ fonts;
    fonts.fontconfig.enable = lib.mkDefault true;
  };
in
{
  options.sol-shell = {
    enable = lib.mkEnableOption "the packages (and, on NixOS, the services) that sol-shell needs";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ./package.nix { }";
      description = "The sol-shell package. By default it is built from your own nixpkgs.";
    };

    themedApps.enable = lib.mkEnableOption ''
      the programs whose colors sol-shell writes to ~/.local/state/theme (Wofi, Thunar
      and Dolphin). Without them the shell works the same, the theme files are just
      not used by anything. Zen browser is not in nixpkgs, so it is not included here
    '';
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (if isNixOS then nixosOnly else { })
    (if isHomeManager then homeManagerOnly else { })
  ]);
}
