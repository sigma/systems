# Nix Configuration — Context

The domain language of this multi-platform Nix configuration (macOS / NixOS / Linux),
centred on how machines are described and how their content is selected. This file is a
glossary, not a spec — it names concepts, it does not record implementation.

## Language

### Machines and hosts

**Host**:
A machine as *declared* in `hosts.nix` — its system, its feature list, its remotes, its
user. The raw input.
_Avoid_: node, box (except in _devbox_, a distinct term).

**Machine**:
A _host_ after resolution — features expanded, remotes turned into _topology_, modules
threaded in. What modules actually see. The resolved form of a _host_.

**Devbox**:
A thin shell *around* per-project Nix devshells. Its real toolchains arrive through
`direnv` and each project's own `flake.nix`; the machine itself carries only the _base
floor_. A devbox is defined by what it deliberately *lacks*, not by a size label — never
call it "minimal."
_Avoid_: minimal machine, lite host, VM (a devbox happens to be a VM, but the term names
the content contract, not the virtualization).

### Topology

**Topology**:
The directed graph of _machines_. An edge `source → target` means the source has some
level of _knowledge_ of the target. Today only one edge kind is _resolved_ — SSH
reachability, declared as a host's _remotes_ — but the graph is broader: parentage
(`devbox.parentHost`), login-trust (`userSshPublicKey`), and build-delegation (`builder`)
are latent edges carried in host data but not yet resolved as topology.
_Avoid_: mesh (implies maintained many-to-many peer connectivity; this is a per-host star
of declared arrows, re-derived for each host, not a shared mesh).

**Remote**:
An edge a _host_ declares: another _machine_ it reaches. Raw, host-declared input
(`host.remotes`) — the SSH-reachability edges of the _topology_.

**Resolved remote**:
A _remote_ after topology resolution — its address computed (shared-domain aware when both
ends allow it) and the reachability quirks each consumer needs already baked in. The unit
consumers read: they render it (SSH config, terminal-multiplexer domains) without
re-deriving any address convention. The per-remote analogue of how a _machine_ is a
resolved _host_.

### Features and content

**Feature**:
A named axis of machine specialization. Two kinds, distinguished by where they are read:
a _structural feature_ or a _content feature_.

**Structural feature**:
A _feature_ read *before* configuration exists or *outside* home scope — at module-import
time, in darwin/NixOS system config, or in host resolution (e.g. `mac`, `nixos`, `laptop`,
`interactive`, `devbox`, `tailscale`, `determinate`, `work`, `firefly`). Carried as plain
host-declared data. `interactive` wires a NixOS desktop session into system config; it is
not the GUI-content axis — home content reads _graphical_ instead.

**Content feature**:
A named axis of *what a machine is equipped to do for its user* (e.g. `dev`, `shell`,
`ai`, `writing`, `media`, `network`, `keyboard`, `music`, `gaming`) — as opposed to a
_structural feature_, which changes module wiring or system identity. A content feature
never alters imports or system identity; it only adds user-facing content. Most of that
content is delivered as home-manager Nix packages/config and read through the resolved
_feature seam_ so a policy can enforce it; but a piece may be delivered through whatever
channel it requires — a homebrew cask, a `launchd` agent, a native app setting — when the
capability is not available in Nix/home scope. The delivery channel is implementation; the
feature names the capability.
_Avoid_: treating "content" as "home-manager content" — that conflates the abstraction
with its most common delivery channel.

**Content-feature registry**:
The canonical list of every _content feature_. The single place the taxonomy is defined;
everything that generates, enforces, or gates on content features derives from it.

**Base floor**:
The home-manager content every machine carries unconditionally, _devbox_ included — the
around-the-toolchain layer: shells, terminal editors, `git`/`jj`, `direnv`, review tools,
a single always-available AI agent (the _floor agent_), mail identity + tooling, core CLI.
Not a _feature_; it is never gated.
_Avoid_: core profile, minimal set.

**Agent roster**:
The canonical list of AI coding agents a _machine_ may carry. Each entry records the agent's
delivery channel per platform, its skill directory, its herdr integration id, its ACP id
(for editors that host external agents), and its default gate: _floor_ (always on — the
_floor agent_, `claude-code`), `ai` (on when the resolved `ai` _content feature_ is), or
off (enabled only by a policy). Everything that installs an agent, registers its skills,
or integrates it with another tool derives from the roster rather than re-deriving which
agents a machine has.
_Avoid_: agent list, agent profile, plan.

**Endpoint variant**:
An agent entry re-pointed at another API endpoint (e.g. `claude-glm`, `claude-firefly`,
`claude-cave` — `claude-code` against GLM, the Aperture gateway, the caveman proxy). A
variant of a _roster_ entry, not an entry of its own: declared as an endpoint on that
entry, which generates the wrapper.
_Avoid_: wrapper (names the delivery, not the concept), plan.

**Graphical**:
The _content feature_ for the headless-vs-graphical axis: fonts and GUI applications
(terminal, GUI editor) a _devbox_ omits because it is a headless VM. A _devbox_ leaves
`graphical` off; a workstation declares it. Every piece of GUI content gates on it (a
platform guard such as `mac` may be added alongside, never substituted).

### The seam

**Feature seam**:
The two-layer split through which _content features_ are read. The *input* layer is the
host's declared feature data (available early and everywhere); the *resolved* layer is a
home option that host declaration and policy compose into by priority. Content reads the
resolved layer, so the _devbox policy_ can override it.
_Avoid_: feature flag (too flat — it hides the input/resolved distinction).

**Devbox policy**:
The authority that pins a _devbox_'s _content feature_ set. It grants the _base floor_'s
allow-set and forces the rest of the _content-feature registry_ off, so a newly added
_content feature_ is absent from devboxes by default.
_Avoid_: devbox profile, minimal profile.
