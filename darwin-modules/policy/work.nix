{ lib, machine, ... }:
with lib;
{
  config = mkIf machine.features.work {
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
  };
}
