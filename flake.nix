{
  description = "Yann's systems";

  inputs = {
    nix-pins.url = "github:firefly-engineering/nix-pins";

    # Package sets (from nix-pins)
    systems.follows = "nix-pins/systems";
    nixpkgs.follows = "nix-pins/nixpkgs";
    nixpkgs-lib.follows = "nix-pins/nixpkgs-lib";
    nixpkgs-stable.follows = "nix-pins/nixpkgs-stable";
    darwin-stable.follows = "nix-pins/darwin-stable";
    nixpkgs-master.follows = "nix-pins/nixpkgs-master";

    # Frameworks (from nix-pins)
    flake-parts.follows = "nix-pins/flake-parts";
    darwin.follows = "nix-pins/darwin";
    home-manager.follows = "nix-pins/home-manager";

    # Rust (from nix-pins)
    fenix.follows = "nix-pins/fenix";
    naersk.follows = "nix-pins/naersk";

    # Utils (from nix-pins)
    flake-compat.follows = "nix-pins/flake-compat";
    flake-utils.follows = "nix-pins/flake-utils";
    flake-root.follows = "nix-pins/flake-root";

    # Shell utils (from nix-pins)
    devshell.follows = "nix-pins/devshell";
    nix-index-database.follows = "nix-pins/nix-index-database";
    treefmt-nix.follows = "nix-pins/treefmt-nix";
    pre-commit-hooks-nix.follows = "nix-pins/pre-commit-hooks-nix";

    # Secrets & infrastructure (from nix-pins)
    sops-nix.follows = "nix-pins/sops-nix";
    nixos-generators.follows = "nix-pins/nixos-generators";
    fh.follows = "nix-pins/fh";

    # Toolbox
    toolbox.url = "github:firefly-engineering/toolbox";
    toolbox.inputs.nix-pins.follows = "nix-pins";
    toolbox.inputs.devenv.follows = "";

    # Personal flakes
    joyride.url = "github:sigma/joyride";
    joyride.inputs.nixpkgs.follows = "nixpkgs";

    maschine-hacks.url = "github:sigma/maschine-hacks";
    maschine-hacks.inputs.nixpkgs.follows = "nixpkgs";
    maschine-hacks.inputs.flake-parts.follows = "flake-parts";

    # Emacs
    emacs.url = "github:nix-community/emacs-overlay";
    emacs.inputs.nixpkgs.follows = "nixpkgs";
    emacs.inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    chemacs2nix.url = "github:league/chemacs2nix";
    chemacs2nix.inputs.home-manager.follows = "home-manager";
    chemacs2nix.inputs.emacs-overlay.follows = "emacs";
    chemacs2nix.inputs.pre-commit-hooks.follows = "pre-commit-hooks-nix";

    # VS Code
    vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    vscode-server.inputs.nixpkgs.follows = "nixpkgs";
    vscode-server.inputs.flake-utils.follows = "flake-utils";

    # Theme
    catppuccin.url = "github:catppuccin/nix/release-25.11";
    catppuccin.inputs.nixpkgs.follows = "nixpkgs-stable";

    # Neovim
    nvf.url = "github:notashelf/nvf";
    nvf.inputs.nixpkgs.follows = "nixpkgs";
    nvf.inputs.flake-compat.follows = "flake-compat";
    nvf.inputs.flake-parts.follows = "flake-parts";
    nvf.inputs.systems.follows = "systems";

    # Flakehub
    nix.url = "https://flakehub.com/f/DeterminateSystems/nix-src/*";
    nix.inputs = {
      nixpkgs.follows = "nixpkgs";
      nixpkgs-regression.follows = "nixpkgs";
      nixpkgs-23-11.follows = "";
      flake-parts.follows = "";
      git-hooks-nix.follows = "";
    };

    # Niri
    noctalia.url = "github:noctalia-dev/noctalia-shell";
    noctalia.inputs.nixpkgs.follows = "nixpkgs";
    noctalia.inputs.noctalia-qs.inputs.systems.follows = "nix-pins/systems";
    noctalia.inputs.noctalia-qs.inputs.treefmt-nix.follows = "nix-pins/treefmt-nix";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./modules
      ];

      systems = import inputs.systems;
    };
}
