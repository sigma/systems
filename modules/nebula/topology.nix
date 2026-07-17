# SSH-reachability projection of the machine topology (see CONTEXT.md).
#
# Resolves a host's declared `remotes` into *resolved remotes*: addresses
# computed (shared-domain aware) and the reachability quirks each consumer needs
# already baked in. Carries no ssh_config or terminal-multiplexer syntax — the
# SSH-config renderer (home ssh settings) and the WezTerm renderer both read the
# resolved facts and render them themselves.
#
# See docs/adr/0001-nixos-remote-forced-tty-and-mux.md for why a NixOS remote
# resolves to two addresses.
{
  lib,
  ...
}:
let
  # Does a raw (host-declared) remote carry a given feature?
  remoteHasFeature = feature: r: builtins.elem feature (r.features or [ ]);
in
{
  # resolveRemotes { features; sharedDomain; } remotes -> [ resolvedRemote ]
  #
  # `features` is the resolving machine's resolved feature set (its own tailscale
  # membership decides whether the shared domain is usable).
  resolveRemotes =
    {
      features,
      sharedDomain,
    }:
    remotes:
    let
      machineHasTailscale = features.tailscale or false;
      resolveOne =
        r:
        let
          hostAlias = if r.alias != null then r.alias else r.name;
          # NixOS remotes force a TTY (fish hangs on `ssh -T`); the reason the
          # `-mux` bypass exists at all. See the ADR.
          needsForcedTTY = remoteHasFeature "nixos" r;
          useSharedDomain =
            machineHasTailscale && remoteHasFeature "tailscale" r && sharedDomain != "";
        in
        {
          name = hostAlias;
          inherit (r) alias user sshOpts;
          inherit needsForcedTTY;
          hostname = if useSharedDomain then "${hostAlias}.${sharedDomain}" else r.name;
          # The single source of the `-mux` convention: the address to target
          # when forced TTY must be bypassed. A remote that does not force a TTY
          # needs no bypass, so its mux address is just the plain alias.
          muxAddress = if needsForcedTTY then "${hostAlias}-mux" else hostAlias;
        };
    in
    map resolveOne remotes;
}
