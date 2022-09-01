{
  description = "Yann's systems";

  inputs = {
    # Package sets
    nixpkgs-nixos.url = github:NixOS/nixpkgs/nixos-21.11;
    nixpkgs-darwin.url = github:NixOS/nixpkgs/nixpkgs-21.11-darwin;
    nixpkgs-unstable.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    # Environment/system management
    darwin.url = github:lnl7/nix-darwin/master;
    darwin.inputs.nixpkgs.follows = "nixpkgs-unstable";
    home-manager.url = github:nix-community/home-manager;
    home-manager.inputs.nixpkgs.follows = "nixpkgs-unstable";
    # Other sources
    emacs.url = github:nix-community/emacs-overlay;
    emacs.inputs.nixpkgs.follows = "nixpkgs-unstable";
    flake-utils.url = github:numtide/flake-utils;
    comma.url = github:nix-community/comma;
    comma.inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  outputs = inputs @ { self, nixpkgs-unstable, darwin, home-manager, comma, emacs, flake-utils, ... }:

    let
      # Configuration for `nixpkgs`
      nixpkgsConfig = {
        config = { allowUnfree = true; };
        overlays = [
          (import ./overlays/nix.nix)
          (import ./overlays/comma.nix comma)
          (import ./overlays/silicon.nix nixpkgs-unstable nixpkgsConfig.config)
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
        inherit (inputs.nixpkgs-unstable) lib;
      };

      gmac = machine: let
        nixpkgs = inputs.nixpkgs-unstable;
        user = users.corpUser;
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
    in
      {
        # My `nix-darwin` configs
        darwinConfigurations = {
          yhodique-macbookpro = gmac hosts.yhodique-macbookpro;
          yhodique-macmini = gmac hosts.yhodique-macmini;
        };

        inherit darwinModules;

        # My home-manager only configs
        homeConfigurations = let
          glinuxUser = users.corpUser;
        in {
          glinux = inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = builtins.getAttr "x86_64-linux" inputs.nixpkgs-unstable.outputs.legacyPackages // nixpkgsConfig;
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

        packages = inputs.home-manager.packages;
      };
}
