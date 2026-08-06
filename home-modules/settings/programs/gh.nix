{ pkgs, ... }:
{
  enable = true;
  settings.pager = "${pkgs.delta}/bin/delta";
}
