# `network` content feature: network tools (see CONTEXT.md).
{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.features.network.enable {
  home.packages = with pkgs; [
    autossh
    lftp
    nmap
    prettyping
  ];
}
