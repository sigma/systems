{ config, pkgs, ... }:
let
  parentDir = config.programs.emacs.chemacs.defaultUserParentDir;
  doomDir = "${parentDir}/doom";
  vanillaDir = "${parentDir}/vanilla";
in
{
  enable = true;

  vanilla.enable = true;
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

    vanilla = {
      userDir = vanillaDir;
      extraPackages = epkgs: with epkgs; [
        # ui
        doom-themes
        doom-modeline
        nerd-icons
        hl-todo
        diff-hl
        which-key
        # completion
        vertico
        vertico-posframe
        marginalia
        orderless
        consult
        embark
        nerd-icons-completion
        corfu
        cape
        # editing
        multiple-cursors
        tempel
        apheleia
        vundo
        smartparens
        envrc
        editorconfig
        # tools
        magit
        eros
        nerd-icons-dired
        # window
        ace-window
        writeroom-mode
      ];
    };
  };
}
