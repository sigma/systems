{
  description = "Yann's systems";

  inputs = {
    # Package sets
    nixpkgs.url = github:nixos/nixpkgs/nixpkgs-unstable;
    nixos-stable.url = github:NixOS/nixpkgs/nixos-22.11;
    darwin-stable.url = github:NixOS/nixpkgs/nixpkgs-22.11-darwin;
    nixpkgs-master.url = github:NixOS/nixpkgs/master;

    # Environment/system management
    darwin.url = github:lnl7/nix-darwin/master;
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = github:nix-community/home-manager;
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.inputs.utils.follows = "utils";

    # Flake compat
    flake-compat = {
      url = github:edolstra/flake-compat;
      flake = false;
    };

    # Other sources
    utils.url = github:gytis-ivaskevicius/flake-utils-plus;
    emacs.url = github:nix-community/emacs-overlay;
    emacs.inputs.nixpkgs.follows = "nixpkgs";
    emacs.inputs.flake-utils.follows = "utils";
    comma.url = github:nix-community/comma;
    comma.inputs.nixpkgs.follows = "nixpkgs";
    comma.inputs.flake-compat.follows = "flake-compat";
    comma.inputs.utils.follows = "utils";
    nix-doom-emacs.url = github:nix-community/nix-doom-emacs;
    nix-doom-emacs.inputs.emacs-overlay.follows = "emacs";
    nix-doom-emacs.inputs.nixpkgs.follows = "nixpkgs";
    nix-doom-emacs.inputs.flake-utils.follows = "utils";
    nix-doom-emacs.inputs.flake-compat.follows = "flake-compat";
    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";

    maschine-hacks.url = github:sigma/maschine-hacks;
    maschine-hacks.inputs.flake-utils.follows = "utils";
    maschine-hacks.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    self, nixpkgs, nixos-stable, darwin-stable, nixpkgs-master,
      darwin, home-manager, comma, emacs, fenix, nix-doom-emacs,
      maschine-hacks, ...
  }: let
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

        # silicon package sets
        (import ./overlays/silicon.nix nixpkgs darwin-stable nixpkgs-master nixpkgsConfig.config)

        # community overlays
        comma.overlays.default
        emacs.overlay
        fenix.overlays.default

        # my overlays
        maschine-hacks.overlays.default

        # packages hacks
        (import ./overlays/pkg)
      ];
    };

    darwinModules = {
    };

    hmModules = [
      ./home.nix
      nix-doom-emacs.hmModule
    ];

    users = import ./users.nix;
    hosts = import ./hosts.nix {
      inherit (nixpkgs) lib;
    };

    mac = machine: let
      user = if machine.isWork then users.corpUser else users.personalUser;
      specialArgs = { inherit user machine; };
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
          home-manager.users.${user.login} = nixpkgs.lib.mkMerge hmModules;
          home-manager.extraSpecialArgs = specialArgs;
        }
      ];
    };

    glinux = machine: let
      user = users.corpUser;
      machine = {isInteractive = false;} // machine // {isWork = true;};
      specialArgs = { inherit user machine; };
    in home-manager.lib.homeManagerConfiguration {
      pkgs = builtins.getAttr "x86_64-linux" nixpkgs.outputs.legacyPackages // nixpkgsConfig;
      modules = hmModules ++ [
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
