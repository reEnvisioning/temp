{
  description = "reShell panel — standalone config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, home-manager }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        # The config tree, built into the Nix store. Usable via
        # `nix run github:reEnvisioning/temp`, `nix build`, or as a flake
        # input (inputs.quickshell.packages.<system>.default).
        packages.default = pkgs.stdenv.mkDerivation {
          name = "reShell";
          src = self;
          installPhase = ''
            mkdir -p $out
            cp -r $src/* $out/
          '';
          phases = [ "installPhase" ];
        };
      })
    // {
      # Home Manager module: `programs.reShell.enable = true;`
      # auto-links the config into the user's ~/.config/quickshell.
      homeManagerModules.default = { config, lib, pkgs, ... }:
        with lib;
        let
          cfg = config.programs.reShell;
          pkg = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
        in {
          options.programs.reShell = {
            enable = mkEnableOption "reShell panel";
            package = mkOption {
              type = types.package;
              default = pkg;
              description = "The quickshell config package to install.";
            };
          };
          config = mkIf cfg.enable {
            home.file."quickshell" = {
              source = cfg.package;
              recursive = true;
              force = true;
            };
          };
        };
    };
}
