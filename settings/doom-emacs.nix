{
  config,
  lib,
  pkgs,
  user,
  machine,
  ...
}: {
  enable = false;
  doomPrivateDir = (import ./doom.d) {
    inherit config lib pkgs user;
  };
  emacsPackage = pkgs.emacs;
}
