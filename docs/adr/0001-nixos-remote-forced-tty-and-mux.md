# SSH topology resolves NixOS remotes to two addresses

## Status

accepted

## Context

_Remotes_ are the SSH-reachability edges of the _topology_ (see `CONTEXT.md`). Host
intake resolves each declared remote into a _resolved remote_, and both consumers of that
resolution — the SSH-config renderer (`home-modules/settings/programs/ssh.nix`) and the
WezTerm domain renderer (`home-modules/settings/programs/wezterm.nix`) — read the resolved
form rather than re-deriving addresses from the raw host data.

A NixOS remote is special: it needs **two** addresses.

- The primary host block forces a TTY (`RequestTTY=force`). Without it, an
  `ssh -T` session lands in `fish`, which hangs waiting on a TTY it never gets.
- WezTerm multiplexing cannot use that same address: forced TTY breaks WezTerm's
  libssh-rs mux protocol, and libssh-rs does not chain SSH-config lookups, so the mux
  target must resolve to a full hostname on its own. It therefore gets a second,
  TTY-free `-mux` alias.

These two requirements are mutually exclusive on a single address — you cannot serve
interactive `fish` and WezTerm mux from the same SSH host entry.

## Decision

A resolved remote for a NixOS host carries both a primary address (forced-TTY) and a
`muxAddress` (the TTY-free `-mux` bypass). `muxAddress` is a first-class field of the
resolved remote, computed **once** during topology resolution — it is the single source
of the `-mux` naming convention. Consumers read `muxAddress`; none of them re-derives the
`-mux` suffix or re-checks the `nixos` feature.

## Consequences

- Adding a third consumer of remotes (e.g. another terminal or a build-dispatch tool)
  reads `muxAddress`/`needsForcedTTY` off the resolved remote; it never re-learns why two
  addresses exist.
- The `nixos` feature check and the `-mux` string literal each appear exactly once, inside
  `modules/nebula/topology.nix`. A change to the convention has one edit site.
- This is a projection decision, not a general topology model: only SSH-reachability edges
  are resolved today. Parentage, login-trust, and build-delegation remain latent edges in
  host data (see `CONTEXT.md`), to be resolved if and when a second projection needs them.
