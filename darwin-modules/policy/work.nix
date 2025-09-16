{ lib, ... }:
with lib;
{
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
}
