# `gaming` content feature: gaming (see CONTEXT.md).
{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.features.gaming.enable {
  home.packages = with pkgs; [
    local.myrient-downloader
  ];
}
