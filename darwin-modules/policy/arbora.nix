{
  lib,
  machine,
  ...
}:
with lib;
{
  config = mkIf machine.features.arbora {
    programs.aerospace.windowRules = mkBefore [
      {
        # Chrome suffixes the "arbora" profile's window title with "(arbora)".
        appId = "com.google.Chrome";
        layout = "tiling";
        windowTitleRegexSubstring = ".*\\(arbora\\)$";
        workspace = "W";
      }
    ];

    homebrew.casks = [
      "brave-browser" # needed for the Google Cloud Console to work
      "notion"
      "notion-cli" # official Notion CLI, provides the `ntn` binary
      "notion-calendar"
    ];
  };
}
