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
  vanillaConfig = pkgs.local.emacs-vanilla-config.override {
    inherit user;
    emacs = cfg.package;
  };
in
{
  options.programs.emacs.vanilla = {
    enable = mkEnableOption "vanilla Emacs profile";
  };

  config = mkIf (cfg.enable && cfg.vanilla.enable) {
    home.file.".config/vanilla".source = "${vanillaConfig}";
  };
}
