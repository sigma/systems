{
  config,
  pkgs,
  extSet,
  lib,
  ...
}:
lib.mkIf config.programs.just.enabled {
  userSettings = {
    "files.associations" = {
      "*.just" = "just";
    };
    "just.executable" = "${pkgs.just}/bin/just";
  };

  extensions = with extSet.vscode-marketplace; [
    skellock.just
  ];
}
