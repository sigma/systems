{
  config,
  lib,
  pkgs,
  machine,
  ...
}:
with lib; let
  cfg = config.programs.tmux;
  mkTop = mkOrder 1;
in
  mkIf (cfg.enable && machine.features.mac && cfg.shell != null) {
    xdg.configFile."tmux/tmux.conf".text = mkTop ''
      set -g default-command "${pkgs.reattach-to-user-namespace}/bin/reattach-to-user-namespace -l ${cfg.shell}"
    '';
  }
