{ config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.modules.editors.emacs;
in {
  options.modules.editors.emacs = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    doom = rec {
      repoUrl = mkOption {
        type = types.str;
        default = "https://github.com/doomemacs/doomemacs";
      };
      configRepoUrl = mkOption {
        type = types.str;
        default = "git@github.com:sigma/doom-emacs-private";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      binutils
      ((emacsPackagesFor emacsNativeComp).emacsWithPackages (epkgs: [
        epkgs.vterm
      ]))

      # Doom dependencies
      (ripgrep.override {withPCRE2 = true;})
      gnutls

      # Module dependencies
      (aspellWithDicts (ds: with ds; [
        en en-computers en-science
      ]))
      editorconfig-core-c
      sqlite
      texlive.combined.scheme-full
      pandoc
    ];

    home.activation = {
      doomActivationAction = lib.hm.dag.entryAfter ["writeBoundary"] ''
        test -d $HOME/.emacs.d || $DRY_RUN_CMD git clone ${cfg.doom.repoUrl} $HOME/.emacs.d
        test -d $HOME/.config/doom || $DRY_RUN_CMD git clone ${cfg.doom.configRepoUrl} $HOME/.config/doom
      '';
    };
  };
}
