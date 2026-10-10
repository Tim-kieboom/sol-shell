# sol-shell as a Nix package: the QML copied into the store, and a `sol-shell` command
# that starts it (and talks to it) without anyone needing to know the store path.
#
# It takes `quickshell` and `qt6` from whatever nixpkgs it is built with, so in a NixOS
# configuration it follows the user's own nixpkgs and Qt stays the same everywhere.
{ lib, stdenvNoCC, symlinkJoin, makeWrapper, quickshell, qt6, pciutils, hyprpicker, coreutils, gnused, getent }:

# the shell is written for Quickshell 0.3 and uses its APIs; an older one fails at runtime
# with QML errors that do not say why
assert lib.assertMsg (lib.versionAtLeast quickshell.version "0.3.0")
  "sol-shell needs Quickshell 0.3.0 or newer, but this nixpkgs has ${quickshell.version}. Use a newer nixpkgs (e.g. nixos-unstable) for the sol-shell package.";

let
  # Quickshell as nixpkgs builds it can read gif, ico, jpeg, png and svg pictures, but
  # not webp (checked: the picture fails with "Unsupported image format"), which the
  # wallpaper picker lists. Qt keeps webp in a separate plugin, so Quickshell is wrapped
  # to find it. The plugin has to come from the same Qt as Quickshell itself, which is
  # why it is taken from the same package set.
  wrappedQuickshell = symlinkJoin {
    name = "quickshell-sol-shell-${quickshell.version}";
    paths = [ quickshell ];
    nativeBuildInputs = [ makeWrapper ];
    postBuild = ''
      # `quickshell` runs the shell, `qs` is the same program under its short name
      # (used for `qs ipc` and `qs log`)
      for program in quickshell qs; do
        wrapProgram $out/bin/$program \
          --prefix QT_PLUGIN_PATH : ${qt6.qtimageformats}/${qt6.qtbase.qtPluginPrefix}
      done
    '';
    meta.mainProgram = "quickshell";
  };
in
stdenvNoCC.mkDerivation {
  pname = "sol-shell";
  version = "0.3.0";

  # only what the shell reads, so editing the README or this file does not rebuild it
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./shell.qml
      ./bin
      ./export
      ./greeter
      ./greeter.qml
      ./lock
      ./notifications
      ./singletons
      ./statusbar
      ./utils
      ./wallpaper
    ];
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/sol-shell $out/bin
    cp -r --no-preserve=mode . $out/share/sol-shell
    chmod +x $out/share/sol-shell/bin/sol-shell  # --no-preserve=mode dropped the x bit
    patchShebangs $out/share/sol-shell/bin

    # SOL_SHELL_DIR is what makes `sol-shell` point at this copy, wherever the store is
    makeWrapper $out/share/sol-shell/bin/sol-shell $out/bin/sol-shell \
      --set SOL_SHELL_DIR $out/share/sol-shell \
      --prefix PATH : ${wrappedQuickshell}/bin \
      --suffix PATH : ${lib.makeBinPath [ pciutils hyprpicker ]}

    # The login screen: the same Quickshell, pointed at greeter.qml, run by greetd as its own
    # user with almost no environment, so what it starts (getent, sed, systemctl) has to be
    # on its PATH. SOL_SHELL_GREETER makes the settings read-only: nobody is logged in yet.
    makeWrapper ${wrappedQuickshell}/bin/quickshell $out/bin/sol-shell-greeter \
      --add-flags "-p $out/share/sol-shell/greeter.qml" \
      --set SOL_SHELL_GREETER 1 \
      --prefix PATH : ${lib.makeBinPath [ coreutils gnused getent ]} \
      --suffix PATH : /run/current-system/sw/bin

    runHook postInstall
  '';

  # the wrapped Quickshell, for the module to install next to `sol-shell`
  passthru.quickshell = wrappedQuickshell;

  meta = {
    homepage = "https://github.com/Tim-kieboom/sol-shell";
    description = "A Hyprland desktop shell (bar, popups, notifications, wallpaper) for Quickshell";
    license = lib.licenses.mit;
    mainProgram = "sol-shell";
    platforms = lib.platforms.linux;
  };
}
