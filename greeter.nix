# The sol-shell login screen, as a NixOS module (not for home-manager: a login screen is a
# system service).
#
#     imports = [ inputs.sol-shell.nixosModules.greeter ];
#     sol-shell.greeter.enable = true;
#     # and turn your current display manager off, for example:
#     services.displayManager.gdm.enable = false;
#
# It sets up greetd (the login daemon) to start a small compositor (cage) that shows the
# login screen (greeter/ in this repository), and starts the session you pick, after the
# password has been checked by PAM. A text console (Ctrl+Alt+F2) always stays available.
{ config, lib, pkgs, ... }:

let
  cfg = config.sol-shell.greeter;

  # the folder with the .desktop files of the sessions that are installed (Hyprland, ...)
  sessions = "${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";

  stateDir = "/var/cache/sol-shell-greeter";

  # what greetd starts: cage (a compositor that shows one program full screen), running the
  # login screen
  launcher = pkgs.writeShellScript "sol-shell-greeter" ''
    export SOL_SHELL_SESSIONS=${sessions}
    export SOL_SHELL_GREETER_STATE=${stateDir}/last-login.json
    ${lib.optionalString (cfg.wallpaper != null) "export SOL_SHELL_WALLPAPER=${cfg.wallpaper}"}
    # what the login screen says goes to a log file, for when it does not come up: nothing
    # else shows it, because nobody is logged in yet
    exec ${lib.getExe pkgs.cage} -s -d -- ${cfg.package}/bin/sol-shell-greeter >> ${stateDir}/greeter.log 2>&1
  '';
in
{
  options.sol-shell.greeter = {
    enable = lib.mkEnableOption "the sol-shell login screen (greetd with a Quickshell greeter)";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ./package.nix { }";
      description = "The sol-shell package. By default it is built from your own nixpkgs.";
    };

    wallpaper = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = lib.literalExpression "./wallpaper.jpg";
      description = ''
        The picture behind the login screen. The default is the painting that ships with
        sol-shell. It has to be readable by every user (it goes in the Nix store when you
        use a path in your configuration), because nobody is logged in yet.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings.default_session.command = "${launcher}";
    };

    # cage draws with the graphics card
    hardware.graphics.enable = lib.mkDefault true;

    # the fonts and icons of the shell, which the login screen shows too
    fonts.packages = [
      pkgs.material-design-icons
      pkgs.nerd-fonts.symbols-only
    ];

    # where the login screen remembers who logged in last and with which session
    systemd.tmpfiles.rules = [
      "d ${stateDir} 0755 ${config.services.greetd.settings.default_session.user} - -"
    ];
  };
}
