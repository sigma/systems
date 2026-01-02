args@{
  pkgs,
  lib,
  machine,
  ...
}:
let
  # Only install on machines with a GUI
  interactive = machine.features.mac || machine.features.interactive;

  makeProfile =
    modules:
    (lib.evalModules {
      modules = [ ./code/module.nix ] ++ modules;
      specialArgs = args // {
        marketplace = pkgs.vscode-marketplace;
        extSet = pkgs.forVSCodeVersion pkgs.vscode.version;
      };
    }).config;
in
{
  enable = interactive;
  mutableExtensionsDir = true;

  profiles.default = makeProfile [
    ./code/cursor.nix
    ./code/custom.nix
    ./code/emacs.nix
    ./code/format.nix
    ./code/go.nix
    ./code/git.nix
    ./code/just.nix
    ./code/k8s.nix
    ./code/nix.nix
    ./code/python.nix
    # ./code/bazel.nix
  ];
}
