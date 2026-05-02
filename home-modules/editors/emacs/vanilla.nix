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
  editorProfile = config.programs.fontProfiles.editor;
  vanillaConfig = pkgs.local.emacs-vanilla-config.override {
    inherit user;
    emacs = cfg.package;
    fonts = {
      family = editorProfile.family.family;
      size = editorProfile.size;
    };
  };
  # Relative path from $HOME to the chemacs vanilla profile directory
  vanillaRelDir = lib.removePrefix "${config.home.homeDirectory}/" "${cfg.chemacs.defaultUserParentDir}/vanilla";
in
{
  options.programs.emacs.vanilla = {
    enable = mkEnableOption "vanilla Emacs profile";
  };

  config = mkIf (cfg.enable && cfg.vanilla.enable) {
    # Deploy tangled config to the chemacs profile directory
    home.file."${vanillaRelDir}".source = "${vanillaConfig}";

    programs.texlive.enable = mkForce true;
    programs.aspell.enable = mkForce true;
    programs.pandoc.enable = mkForce true;

    home.packages = with pkgs; [
      sqlite # org-roam/emacsql
    ];
  };
}
