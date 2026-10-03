# `keyboard` content feature: keyboard firmware tooling (see CONTEXT.md).
{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.features.keyboard.enable {
  home.packages = with pkgs; [
    local.mdloader # QMK
  ];
}
