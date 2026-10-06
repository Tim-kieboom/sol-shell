{
  description = "sol-shell: a Hyprland desktop shell for Quickshell";

  # This nixpkgs is only used for `nix build` and the tests in this repository. When
  # sol-shell is used from a NixOS configuration, the module builds the package from
  # the user's own nixpkgs, so nothing here has to match theirs.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        sol-shell = pkgs.callPackage ./package.nix { };
        default = sol-shell;
      });

      # in your NixOS configuration:
      #     imports = [ inputs.sol-shell.nixosModules.default ];
      #     sol-shell.enable = true;
      nixosModules.default = ./quickshell.nix;
    };
}
