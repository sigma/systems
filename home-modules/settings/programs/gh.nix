{ config, pkgs, ... }:
{
  inherit (config.features.dev) enable;
  settings.pager = "${pkgs.delta}/bin/delta";
}
