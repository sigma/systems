# `media` content feature: media tooling (see CONTEXT.md).
{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.features.media.enable {
  home.packages = with pkgs; [
    ffmpeg
    local.m3ugen
  ];
}
