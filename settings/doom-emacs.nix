{
  config,
  lib,
  pkgs,
  user,
  machine,
  ...
}: {
  enable = true;
  doomPrivateDir = (import ./doom.d) {
    inherit config lib pkgs user;
  };
  emacsPackage = pkgs.emacsUnstable;
}
