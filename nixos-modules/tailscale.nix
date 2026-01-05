# Tailscale VPN configuration for NixOS
# Reference: https://nixos.wiki/wiki/Tailscale
{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.tailscale = {
    enable = true;

    # Disable telemetry and logging
    extraDaemonFlags = [ "--no-logs-no-support" ];

    # Prevent Tailscale from bypassing NixOS firewall rules
    # By default, Tailscale injects a rule accepting all incoming traffic
    # on tailscale0, which bypasses firewall rules. This disables that.
    extraSetFlags = [ "--netfilter-mode=nodivert" ];
  };

  # Fix reverse path filtering issues with Tailscale
  networking.firewall.checkReversePath = "loose";

  # Trust the tailscale interface for firewall purposes
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  # Allow Tailscale UDP port through firewall
  networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];
}
