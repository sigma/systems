{pkgs, ...}: {
  enable = true;
  extraConfig = ''
    package.path = package.path .. ";${pkgs.wezterm-config}/?.lua;${pkgs.wezterm-config}/?/init.lua"

    return dofile("${pkgs.wezterm-config}/wezterm.lua")
  '';
}
