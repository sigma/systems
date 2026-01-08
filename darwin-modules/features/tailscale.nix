{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.features.tailscale;
in
{
  options.features.tailscale = {
    enable = mkEnableOption "Tailscale VPN";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [ "tailscale-app" ];
  };
}
