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
      {
        # Chrome suffixes the "firefly" profile's window title with "(firefly)".
        appId = "com.google.Chrome";
        layout = "tiling";
        windowTitleRegexSubstring = ".*\\(firefly\\)$";
        workspace = "W";
      }
    ];

    # Enable darwin-level claude-code module (installs via homebrew, provides wrapper)
    programs.claude-code.enable = true;

    homebrew.casks = [
      "linear"
      "notion"
      "notion-cli" # official Notion CLI, provides the `ntn` binary
      "notion-calendar"
      "slack"
    ];
  };
}
