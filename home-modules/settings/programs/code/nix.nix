{
  pkgs,
  extSet,
  ...
}:
{
  userSettings = {
    "nix.enableLanguageServer" = true;
    "nix.serverPath" = "${pkgs.nil}/bin/nil";
    "nix.serverSettings" = {
      "nil" = {
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
  };

  extensions = with extSet.vscode-marketplace; [
    arrterian.nix-env-selector
    jnoortheen.nix-ide
    mkhl.direnv
  ];
}
