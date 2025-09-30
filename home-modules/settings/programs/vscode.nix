args@{
  pkgs,
  lib,
  ...
}:
let
  makeProfile =
    modules:
    (lib.evalModules {
      modules = [ ./code/module.nix ] ++ modules;
      specialArgs = args // {
        extSet = pkgs.forVSCodeVersion pkgs.vscode.version;
      };
    }).config;
in
{
  enable = true;
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
    ./code/bazel.nix
  ];
}
