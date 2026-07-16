# Issue tracker: Beadwork (`bw`)

Issues, epics, and plans for this repo live in **beadwork**, a lightweight
git-native issue tracker. Everything is managed through the `bw` CLI and
persisted to the `beadwork` branch, so state survives compaction and session
boundaries. Issue IDs look like `nix-XYZ`.

**Always run `bw prime` before starting work** — it prints current workflow
context, work-in-progress, and available tickets.

## Model

- **Status**: `open` → `in_progress` → `closed` / `deferred`
- **Priority**: `P0`–`P4` (default `P2`)
- **Types**: `task`, `epic` (`-t`). Epics have children (`--parent`) and
  dependencies (`bw dep add <blocker> blocks <blocked>`).
- **Due dates**: `bw update <id> --due <date>` — deadlines that don't change
  status. Date expressions: `YYYY-MM-DD`, `tomorrow`, `2 weeks`, `next monday`,
  `in 15 minutes`, `3pm`, or full RFC3339.

## Operations

- **Create**: `bw create "Title" --description "..." -t task`
- **Read**: `bw show <id>` (add `--json` for raw data)
- **List**: `bw list [flags]` (`--overdue`, `--json`, etc.)
- **Comment**: `bw comment <id> "..."` — leave breadcrumbs
- **Apply / remove labels**: `bw label <id> +label [-label]`
- **Start / close / reopen**: `bw start <id>` / `bw close <id>` / `bw reopen <id>`
- **Defer / undefer**: `bw defer <id> <when>` / `bw undefer <id>`
- **Dependencies**: `bw dep add <id> blocks <id>`
- **Find work**: `bw ready` (unblocked) / `bw blocked`
- **Sync**: `bw sync` (fetch, rebase/replay, push)

Run `bw --help` or `bw <command> --help` for the full surface.

## No pull-request triage surface

This repo does not treat external PRs as a request surface. `/triage` only
processes beadwork issues.

## When a skill says "publish to the issue tracker"

Create a beadwork issue: `bw create "Title" --description "..." -t task`.
For multi-step work, create an epic (`-t epic`) with child tasks
(`--parent <epic>`) and wire dependencies (`bw dep add <blocker> blocks
<blocked>`).

## When a skill says "fetch the relevant ticket"

Run `bw show <id>` (the user will normally pass the `nix-XYZ` ID).

## Workflow — parallel jj changes, no worktrees

This repo does **not** use git worktrees. Parallel development is done with
sibling `jj` changes reconciled by a single "mega-merge" commit at the top,
using `jj-hunk` (from the toolbox, available in this repo's devshell) to
dispatch hunks into the right change.

- **One change per ticket**: give each ticket its own jj change, described with
  the ticket ID (`jj describe -m "…  (nix-XYZ)"`), based off a shared parent so
  changes stay independent rather than forming a linear stack.
- **Claim**: `bw start <id>` before working the change.
- **Dispatch hunks**: when edits for several tickets accumulate in one working
  copy, split them apart with `jj-hunk`:
  - `jj-hunk list` — inspect the pending hunks
  - `jj-hunk split '<hunkset>' 'message (nix-XYZ)'` — peel a subset into its own
    change
  - `jj-hunk squash '<hunkset>'` — fold selected hunks into the parent change

  so each ticket's change stays self-contained.
- **Mega-merge**: integrate the parallel changes with a single merge commit at
  the top (`jj new <change-a> <change-b> …`); that merge is the combined working
  state you build/activate (`home-test`, `system-test`, etc.).
- **Land**: once a ticket's change is final and references the ticket ID,
  `bw close <id>` → `bw sync`.

## Wayfinding operations

Used by `/wayfinder`. The **map** is an epic; **child** tickets are its children.

- **Map**: `bw create "<effort> map" -t epic` — holds the Notes /
  Decisions-so-far / Fog body in its description.
- **Child ticket**: `bw create "<question>" --parent <map-id> -t task`. Record
  the ticket type (`research`/`prototype`/`grilling`/`task`) as a label
  (`bw label <id> +wayfinder:<type>`).
- **Blocking**: `bw dep add <blocker> blocks <blocked>`. A ticket is unblocked
  when all its blockers are closed.
- **Frontier**: `bw ready` lists open, unblocked, unclaimed tickets; scope to
  the map's children and take the first.
- **Claim**: `bw start <id>` before any work.
- **Resolve**: `bw comment <id> "<answer>"`, then `bw close <id>`, then append a
  context pointer to the map's Decisions-so-far (`bw comment <map-id> "..."`).
