{
  pkgs,
  extSet,
  ...
}:
{
  userSettings = {
    "nix.enableLanguageServer" = true;
    "nix.serverPath" = "${pkgs.nixd}/bin/nixd";
    "nix.serverSettings" = {
      "nixd" = {
        "formatting" = {
          "command" = [
            "${pkgs.nixfmt}/bin/nixfmt"
          ];
        };
      };
    };
    "[nix]" = {
      "editor.formatOnSave" = true;
    };

    "direnv.path.executable" = "${pkgs.direnv}/bin/direnv";
  };

  extensions = with extSet.vscode-marketplace; [
    arrterian.nix-env-selector
    jnoortheen.nix-ide
    mkhl.direnv
  ];
}
