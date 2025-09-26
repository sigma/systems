{
  lib,
  pkgs,
  config,
  ...
}:
let
  weztermConfig = pkgs.local.wezterm-config;
in
{
  enable = true;
  extraConfig = ''
    package.path = package.path .. ";${weztermConfig}/?.lua;${weztermConfig}/?/init.lua"

    local config = dofile("${weztermConfig}/wezterm.lua")${lib.optionalString config.catppuccin.wezterm.enable ":apply(dofile(catppuccin_plugin))"}
    return config.options
  '';
}
