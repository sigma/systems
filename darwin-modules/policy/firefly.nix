{
  lib,
  machine,
  ...
}:
with lib;
{
  config = mkIf machine.features.firefly {
    programs.aerospace.workspaces = mkBefore [
      {
        name = "P"; # Projects
        display = "main";
      }
    ];
    programs.aerospace.windowRules = mkBefore [
      {
        appId = "com.linear";
        layout = "tiling";
        workspace = "P";
      }
    ];

    # Enable darwin-level claude-code module (installs via homebrew, provides wrapper)
    programs.claude-code.enable = true;

    homebrew.casks = [
      "linear-linear"
      "notion"
      "notion-calendar"
      "slack"
    ];
  };
}
