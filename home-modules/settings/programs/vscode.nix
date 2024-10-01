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
      };
    })
    .config;
in
  {
    enable = true;
    mutableExtensionsDir = true;
  }
  // (makeProfile [
    ./code/custom.nix
    ./code/go.nix
    ./code/git.nix
    ./code/nix.nix
    ./code/bazel.nix
  ])
