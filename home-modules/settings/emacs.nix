{config, ...}: let
  doomDir = "${config.programs.emacs.chemacs.defaultUserParentDir}/doom";
in {
  enable = true;

  doom.dir = doomDir;
  chemacs.profiles = {
    default = {
      userDir = doomDir;
      env.DOOMDIR = "~/.config/doom";
    };

    doom-dev = {
      userDir = doomDir;
      env.DOOMDIR = "~/.config/nix/overlays/pkg/local/emacs-config";
    };
  };
}
