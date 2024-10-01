{
  config,
  lib,
  ...
}: let
  cfg = config.programs.tailscale;
in
  with lib; {
    options.programs.tailscale = {
      enable = mkEnableOption "Tailscale";
    };
    config = mkIf cfg.enable {
      homebrew.casks = [
        "tailscale"
      ];
    };
  }
