{
  config,
  lib,
  pkgs,
  user,
  ...
}: {
  enable = false;
  doomPrivateDir = (import ./doom.d) {
    inherit config lib pkgs user;
  };
  emacsPackage = pkgs.emacs;
}
