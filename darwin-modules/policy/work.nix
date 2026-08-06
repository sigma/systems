{ lib, machine, ... }:
with lib;
{
  config = mkIf machine.features.work {
    features.ipfs.enable = mkForce false;

    programs.onepassword.enable = mkForce true;

    programs.aerospace.workspaces = mkBefore [
      {
        name = "W"; # Work
        display = "main";
      }
    ];
    programs.aerospace.windowRules = mkBefore [
      {
        appId = "com.brave.Browser";
        layout = "tiling";
        windowTitleRegexSubstring = ".*- Work$";
        workspace = "W";
      }
    ];
  };
}
