{
  config,
  lib,
  pkgs,
  user,
  ...
}:
with lib;
let
  cfg = config.programs.emacs;
  emacsConfig = pkgs.local.emacs-config.override {
    inherit user;
    emacs = cfg.package;
  };
in
{
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
    # needed for Doom.
    programs.ripgrep.enable = mkForce true;

    programs.texlive.enable = mkForce true;
    programs.aspell.enable = mkForce true;
    programs.pandoc.enable = mkForce true;

    home.packages = with pkgs; [
      binutils

      # Doom dependencies
      gnutls

      # Module dependencies
      editorconfig-core-c
      sqlite
    ];

    home.activation = {
      doomActivationAction = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        test -d ${cfg.doom.dir} || $DRY_RUN_CMD ${pkgs.git}/bin/git clone ${cfg.doom.repoUrl} ${cfg.doom.dir}
      '';
    };

    home.file.".config/doom".source = "${emacsConfig}";
  };
}
