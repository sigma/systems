args@{
  config,
  pkgs,
  lib,
  machine,
  ...
}:
let
  # Only install on machines with a GUI
  interactive = machine.features.mac || machine.features.interactive;

  profiles = config.programs.fontProfiles;
  fbName = f: if lib.isString f then f else f.family;
  joinFamilies = p: lib.concatStringsSep ", " ([ p.family.family ] ++ map fbName p.fallbacks);
  joinFeatures = fs: lib.concatMapStringsSep ", " (f: "'${f}'") fs;

  fontsModule = {
    userSettings = {
      "editor.fontFamily" = joinFamilies profiles.editor;
      "editor.fontSize" = profiles.editor.size;
      "editor.fontLigatures" = joinFeatures profiles.editor.features;
      "terminal.integrated.fontFamily" = joinFamilies profiles.terminal;
      "terminal.integrated.fontSize" = profiles.terminal.size;
      "terminal.integrated.fontWeight" = toString profiles.terminal.weight;
    };
  };

  makeProfile =
    modules:
    (lib.evalModules {
      modules = [
        ./code/module.nix
        fontsModule
      ] ++ modules;
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
    ./code/antigravity.nix
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
