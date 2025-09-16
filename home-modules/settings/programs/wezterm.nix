{
  lib,
  pkgs,
  config,
  ...
}:
{
  enable = true;
  extraConfig = ''
    package.path = package.path .. ";${pkgs.wezterm-config}/?.lua;${pkgs.wezterm-config}/?/init.lua"

    local config = dofile("${pkgs.wezterm-config}/wezterm.lua")${lib.optionalString config.catppuccin.wezterm.enable ":apply(dofile(catppuccin_plugin))"}
    return config.options
  '';
}
