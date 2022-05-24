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

    gmac = mod: import mod {
        nixpkgs = inputs.nixpkgs-unstable;
        inherit nixpkgsConfig darwin darwinModules home-manager;
        user = users.corpUser;
    };

    glinuxUser = users.corpUser;
  in
  {
    # My `nix-darwin` configs
    darwinConfigurations = {
      yhodique-macbookpro = gmac ./hosts/yhodique-macbookpro.roam.internal.nix;
    };

    inherit darwinModules;

    # My home-manager only configs
    homeConfigurations = {
      glinux = inputs.home-manager.lib.homeManagerConfiguration {
        configuration = import ./home.nix;
        system = "x86_64-linux";
        username = glinuxUser.login;
        homeDirectory = "/usr/local/google/home/${glinuxUser.login}";
	      stateVersion = "22.05";
	      pkgs = builtins.getAttr "x86_64-linux" inputs.nixpkgs-unstable.outputs.legacyPackages // nixpkgsConfig;
        extraSpecialArgs = {
          user = glinuxUser;
        };
      };
    };

    packages = inputs.home-manager.packages;
  };
}
