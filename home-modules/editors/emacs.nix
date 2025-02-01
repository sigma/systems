{
  config,
  lib,
  pkgs,
  user,
  ...
}:
with lib; let
  cfg = config.programs.emacs;
  emacsConfig = pkgs.emacs-config.override {
    inherit user;
    emacs = cfg.package;
  };
in {
  options.programs.emacs = {
    doom = {
      repoUrl = mkOption {
        type = types.str;
        default = "https://github.com/doomemacs/doomemacs";
      };
      dir = mkOption {
        type = types.str;
        default = "${config.home.homeDirectory}/.config/emacs";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; let
      tex = texlive.combine {
        inherit
          (texlive)
          scheme-basic
          dvisvgm
          dvipng # for preview and export as html
          wrapfig
          amsmath
          ulem
          hyperref
          capt-of
          ;
        #(setq org-latex-compiler "lualatex")
        #(setq org-preview-latex-default-process 'dvisvgm)
      };
    in [
      binutils

      # Doom dependencies
      (ripgrep.override {withPCRE2 = true;})
      gnutls

      # Module dependencies
      (aspellWithDicts (ds:
        with ds; [
          en
          en-computers
          en-science
        ]))
      editorconfig-core-c
      sqlite
      # texlive.combined.scheme-full
      pandoc
    ];

    home.activation = {
      doomActivationAction = lib.hm.dag.entryAfter ["writeBoundary"] ''
        test -d ${cfg.doom.dir} || $DRY_RUN_CMD ${pkgs.git}/bin/git clone ${cfg.doom.repoUrl} ${cfg.doom.dir}
      '';
    };

    home.file.".config/doom".source = "${emacsConfig}";
  };
}
