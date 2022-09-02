{
  description = "Yann's systems";

  inputs = {
    # Package sets
    nixpkgs.url = github:nixos/nixpkgs/nixpkgs-unstable;
    nixos-stable.url = github:NixOS/nixpkgs/nixos-21.11;
    darwin-stable.url = github:NixOS/nixpkgs/nixpkgs-21.11-darwin;
    nixpkgs-master.url = github:NixOS/nixpkgs/master;

    # Environment/system management
    darwin.url = github:lnl7/nix-darwin/master;
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = github:nix-community/home-manager;
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Other sources
    emacs.url = github:nix-community/emacs-overlay;
    emacs.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = github:numtide/flake-utils;
    comma.url = github:nix-community/comma;
    comma.inputs.nixpkgs.follows = "nixpkgs";
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
              system = prev.stdenv.system;
              nixpkgs-stable = if final.stdenv.isDarwin then darwin-stable else nixos-stable;
            in {
              master = nixpkgs-master.legacyPackages.${system};
              stable = nixpkgs-stable.legacyPackages.${system};
            }
          )
          (import ./overlays/nix.nix)
          (import ./overlays/comma.nix comma)
          (import ./overlays/silicon.nix nixpkgs darwin-stable nixpkgs-master nixpkgsConfig.config)
          emacs.overlay
          (import ./overlays/emacs.nix)
          (import ./overlays/zinit.nix)
          (import ./overlays/google.nix)
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
        specialArgs = {
          inherit user machine;
        };
        user = if machine.isWork then users.corpUser else users.personalUser;
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

    in
      {
        # My `nix-darwin` configs
        darwinConfigurations = {
          yhodique-macbookpro = mac hosts.yhodique-macbookpro;
          yhodique-macmini = mac hosts.yhodique-macmini;
        };

        inherit darwinModules;

        # My home-manager only configs
        homeConfigurations = let
          glinuxUser = users.corpUser;
        in {
          glinux = home-manager.lib.homeManagerConfiguration {
            pkgs = builtins.getAttr "x86_64-linux" nixpkgs.outputs.legacyPackages // nixpkgsConfig;
            modules = [
              ./home.nix
              {
                home = {
                  username = glinuxUser.login;
                  homeDirectory = "/usr/local/google/home/${glinuxUser.login}";
                  stateVersion = "22.11";
                };
              }
            ];
            extraSpecialArgs = {
              user = glinuxUser;
              machine = {};
            };
          };
        };

        packages = home-manager.packages;
      };
}
