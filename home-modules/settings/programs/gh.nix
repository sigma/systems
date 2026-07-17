{ config, pkgs, ... }:
{
  enable = config.features.dev.enable;
  settings.pager = "${pkgs.delta}/bin/delta";
}
