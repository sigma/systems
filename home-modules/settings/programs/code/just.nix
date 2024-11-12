{
  pkgs,
  extSet,
  ...
}: {
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
