{pkgs, ...}: {
  userSettings = {
    "nix.enableLanguageServer" = true;
    "nix.serverPath" = "${pkgs.nil}/bin/nil";
    "nix.serverSettings" = {
      "nil" = {
        "formatting" = {
          "command" = [
            "${pkgs.alejandra}/bin/alejandra"
          ];
        };
      };
    };
    "[nix]" = {
      "editor.formatOnSave" = true;
    };
  };
}
