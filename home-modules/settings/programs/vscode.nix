{
  config,
  pkgs,
  lib,
  machine,
  user,
  ...
}: let
  makeProfile = modules:
    (lib.evalModules {
      modules = [./code/module.nix] ++ modules;
      specialArgs = {
        inherit config pkgs lib machine user;
        extSet = pkgs.forVSCodeVersion pkgs.vscode.version;
      };
    })
    .config;
in
  {
    enable = true;
    mutableExtensionsDir = true;
  }
  // (makeProfile [
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
  ])
