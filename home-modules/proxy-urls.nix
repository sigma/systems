# Shared API proxy URLs for endpoint variants (claude-firefly, caveman-proxy).
#
# Fully qualified so resolution does not depend on the MagicDNS search domain
# (absent on hosts running with --accept-dns=false); the domain is the
# tailnet's, from host data (`nebula.sharedDomain`, surfaced as
# machine.sharedDomain).
sharedDomain:
let
  apertureHost = "aperture.${sharedDomain}";
in
{
  # Plain-HTTP host:port of the tailnet's Aperture gateway.
  aperture = "${apertureHost}:80";
  tailscaleProxy = "http://${apertureHost}";
}
