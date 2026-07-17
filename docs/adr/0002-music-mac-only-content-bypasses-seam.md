# Music is Mac-only content and bypasses the content-feature seam

`music` is a content feature, but every channel it delivers through is macOS-only: homebrew
casks (Ableton, Arturia, …), an aerospace window layout, a `launchd` RTP-MIDI agent, and
`maschine-hacks` (a patch to the Mac Native Instruments software). We therefore aggregate
all of it into a single darwin module (`darwin-modules/features/music.nix`) gated on
`machine.features.music`, delivering the one home package through `user.home.packages` —
rather than reading the resolved home _feature seam_ the way other content features do.

## Considered Options

- **(A, chosen)** One darwin module, gated structurally on `machine.features.music`.
  "Mac-only" becomes structural — a darwin module cannot reach Linux — so no per-package
  platform guard can be forgotten. The generated home option `config.features.music.enable`
  is left unread.
- **(B)** Keep `maschine-hacks` in a home module reading the seam, to stay uniform with
  every other content feature. Rejected: it keeps music split across two module trees and
  needs an explicit `machine.features.mac` guard to avoid installing a Mac-only patch on a
  Linux host.

## Consequences

- `music` stays in the content-feature registry for taxonomy completeness, but its home
  seam option is unread; the devbox policy still forces it off on devboxes — harmless, since
  a devbox is a headless Linux VM and carries none of music's macOS content anyway.
- If a genuinely cross-platform music tool ever appears, revisit this: deliver that piece
  through the home seam, and this ADR no longer covers it.
