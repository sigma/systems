{
  description = "Yann's systems";

  inputs = {
    # Package sets
    nixpkgs.url = github:nixos/nixpkgs/nixpkgs-unstable;
    nixos-stable.url = github:NixOS/nixpkgs/nixos-22.05;
    darwin-stable.url = github:NixOS/nixpkgs/nixpkgs-22.05-darwin;
    nixpkgs-master.url = github:NixOS/nixpkgs/master;

    # Environment/system management
    darwin.url = github:lnl7/nix-darwin/master;
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = github:nix-community/home-manager;
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.inputs.utils.follows = "flake-utils";

    # Other sources
    flake-utils.url = github:numtide/flake-utils;
    emacs.url = github:nix-community/emacs-overlay;
    emacs.inputs.nixpkgs.follows = "nixpkgs";
    emacs.inputs.flake-utils.follows = "flake-utils";
    comma.url = github:nix-community/comma;
    comma.inputs.nixpkgs.follows = "nixpkgs";
    comma.inputs.utils.follows = "flake-utils";
  };

  outputs = inputs @ { self, nixpkgs, nixos-stable, darwin-stable, nixpkgs-master, darwin, home-manager, comma, emacs, flake-utils, ... }:

    let
      # Configuration for `nixpkgs`
      nixpkgsConfig = {
        config = { allowUnfree = true; };
        overlays = [
          # Add stable and master package sets for convenience
          (
            final: prev:
            let
              system = final.stdenv.system;
              nixpkgs-stable = if final.stdenv.isDarwin then darwin-stable else nixos-stable;
            in {
              master = nixpkgs-master.legacyPackages.${system};
              stable = nixpkgs-stable.legacyPackages.${system};
            }
          )
          (import ./overlays/nix.nix)
          (import ./overlays/comma.nix comma)
          (import ./overlays/notmuch.nix)
          (import ./overlays/silicon.nix nixpkgs darwin-stable nixpkgs-master nixpkgsConfig.config)
          emacs.overlay
          (import ./overlays/emacs.nix)
          (import ./overlays/zinit.nix)
          (import ./overlays/google.nix)
          (import ./overlays/afsctool.nix)
        ];
      };

      darwinModules = {
        link-apps = (import ./modules/link-apps);
      };

      users = import ./users.nix;
      hosts = import ./hosts.nix {
        inherit (nixpkgs) lib;
      };

      mac = machine: let
        user = if machine.isWork then users.corpUser else users.personalUser;
        specialArgs = {
          inherit user machine;
        };
      in darwin.lib.darwinSystem {
        inherit (machine) system;
        inherit specialArgs;
        modules = nixpkgs.lib.attrValues darwinModules ++ [
          # Main `nix-darwin` config
          ./configuration.nix
          ./mac-user.nix
          # `home-manager` module
          home-manager.darwinModules.home-manager
          {
            nixpkgs = nixpkgsConfig;
            # `home-manager` config
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${user.login} = import ./home.nix;
            home-manager.extraSpecialArgs = specialArgs;
          }
        ];
      };

      glinux = machine: let
        user = users.corpUser;
        specialArgs = {
          inherit user machine;
        };
      in home-manager.lib.homeManagerConfiguration {
        pkgs = builtins.getAttr "x86_64-linux" nixpkgs.outputs.legacyPackages // nixpkgsConfig;
        modules = [
          ./home.nix
          {
            home = {
              username = user.login;
              homeDirectory = "/usr/local/google/home/${user.login}";
              stateVersion = "22.11";
            };
          }
        ];
        extraSpecialArgs = specialArgs;
      };

    in
      {
        # My `nix-darwin` configs
        darwinConfigurations = {
          yhodique-macbookpro = mac hosts.yhodique-macbookpro;
          yhodique-macmini = mac hosts.yhodique-macmini;
        };
        inherit darwinModules;

        # My home-manager only configs
        homeConfigurations = {
          glinux = glinux {};
          shirka = glinux hosts.shirka;
          ghost-wheel = glinux hosts.ghost-wheel;
        };

        packages = home-manager.packages;
      };
}
