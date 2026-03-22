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

    # LSP servers for eglot
    home.packages = with pkgs; [
      gopls
      rust-analyzer
      pyright
      nil
      nodePackages.typescript-language-server
      clang-tools
      lua-language-server
      yaml-language-server
      texlab
    ];
  };
}
