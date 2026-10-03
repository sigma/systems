# Shared API proxy URL constants for wrapper modules.
# Centralizes endpoint URLs so they aren't duplicated across
# claude-firefly.nix, caveman-proxy, etc.
#
# Fully qualified so resolution does not depend on the MagicDNS search domain
# (absent on hosts running with --accept-dns=false).
let
  apertureHost = "aperture.van-scylla.ts.net";
in
{
  # Plain-HTTP host:port of the tailnet's Aperture gateway.
  aperture = "${apertureHost}:80";
  tailscaleProxy = "http://${apertureHost}";
}
