{ extSet, ... }:
{
  extensions = with extSet.vscode-marketplace; [
    esbenp.prettier-vscode
  ];

  userSettings = {
    "[typescript]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
    };
    "[jsonc]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
    };
    "[javascript]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
    };
  };
}
