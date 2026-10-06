# Personal engineering discipline (global)

This is my **global** agent-context layer — principles and preferences that hold
across *all* my projects. Anything specific to a single codebase belongs in that
repo's own committed `./CLAUDE.md`, not here.

## How to record feedback

When I correct you or state a preference, classify it before saving:

- **General principle** (would hold in any of my repos) → propose an edit to this
  file, `~/.claude/CLAUDE.md`.
- **Project-specific** (about this codebase's architecture, conventions, or goals) →
  propose an edit to the repo's `./CLAUDE.md`.

Tell me which file, show me the diff, and wait for my approval before writing. If the
rule is mechanically checkable, also propose a lint, test, or hook that enforces it —
prose here only *influences* you; a check actually *enforces*.

## Anti-patterns I reject

- Don't build parsers on regex-based logic — it's too brittle and breeds unnecessary
  corner cases. Reach for a real tokenizer/parser or a proper grammar instead.

- Don't replicate a dependency's constants as local literals — import them. They are
  implementation details and must be consumed as such; a copy is a second source of
  truth, and a test that guards it has to import the dependency anyway, so it proves
  only that the copy matches its own source.

- If code depends on a wire or file format produced by a pinned binary, the library
  that mirrors that format is pinned to the **same exact version**, never a range.
  A caret range lets a routine dependency update move what the code believes about
  the format with no change to the tool that produces it. Pin them together, bump
  them together.

- Don't reach code through process-global state: no `os.Setenv`/`t.Setenv`, no
  `os.Chdir`/`t.Chdir`, and no library reading an environment variable or the working
  directory to find a collaborator. Inject it through an explicit parameter or seam,
  so tests stay parallel-safe (`t.Setenv` and `t.Chdir` panic under `t.Parallel`).
  Handing a value to a child process on that command's own environment or working
  directory (`cmd.Env`, `cmd.Dir`) is fine: it's an explicit input to that process,
  read once by its `main`.

- Don't build a release artifact on a laptop to get round a CI that can't build
  it yet. Fix the CI first: an artifact others pin must come from a run anyone can
  inspect, and a local build has no provenance.

## Tooling & language defaults

### Nix: keep invocations cheap

Nix will happily saturate every core on my machine and drown the tool pipe. Three
rules, in order of how much they actually buy:

- **Evaluate the narrowest attribute that answers the question.** Reach for
  `.#homeConfigurations.<host>.config.programs.foo.enable`, not a whole
  `activationPackage` or `system.build.toplevel`, when a single option settles it.
  Realising a full system closure to read one value is the most common way an
  "innocent" `nix eval` turns into a ten-minute CPU fire.

- **Keep the output quiet.** Add `--quiet`, and `--no-link` on builds. When you do
  need the full log, send it to `/tmp/nix-out.txt` and read the tail — piping a raw
  build stream through `grep`/`jq` costs tokens and buys nothing. Filter with `--raw`
  / `--json` + `--apply` inside the Nix invocation instead.

Ask me before running anything that rebuilds a full system or home closure. `nix build` on a package or a narrow attribute needs no permission.

### Repo-wide formatters

`nix fmt` / `treefmt` / `prettier .` reformat the *whole tree*, not my diff. Where a
repo has pre-existing formatting drift, that buries my change under dozens of
unrelated files. Format only the files I touched (`nixfmt path/to/file.nix`,
`prettier --write <files>`). Run the repo-wide formatter only when I ask for it, or
when it is a CI gate — and then in check mode first, so the drift is visible before
anything is rewritten.

## Review expectations

- When my stated preference conflicts with a constraint you introduced yourself
  (in a recommendation, a spec you drafted, or a decision you proposed), name the
  constraint and ask whether it still stands. Don't quietly work around my
  preference to preserve it.

## Working in a repo

- Whenever you navigate the filesystem, anchor to the repo root and use relative
  paths from there. Resolve the root with `jj root` when inside a jj repo, falling
  back to `git rev-parse --show-toplevel` otherwise. This is load-bearing inside a
  jj *workspace*: a secondary workspace has no own `.git`, so
  `git rev-parse --show-toplevel` silently resolves to the *main* repo and any work
  you do lands outside your isolated workspace. `jj root` reports the workspace.

- In a jj repo, **run `jj new` before starting each new unit of work** — a ticket, a
  fix, a refactor. Do not begin editing in whatever change happens to be current.
  jj has no staging area and no "dirty tree" state: edits land silently in `@`, so
  writing new work on top of an already-described change quietly amends *that*
  change, and the description now lies about its contents. Untangling it afterwards
  is manual, because a single file usually holds both units.

  Check before the first edit: if `@` already has a description, or `jj st` shows
  changes you did not just make, run `jj new` first.

  The same applies in reverse when finishing: `jj new` after describing, or the next
  edit reopens the change you just closed.

- **Abandon throwaway jj changes as soon as they have served their purpose**, and
  never leave `@` sitting on one. Deliberately-broken changes — proving a gate goes
  red, reproducing a bug — leave their breakage in the *working copy*, so anything
  done next is built on top of it. `jj abandon <change>` and confirm `jj st` is clean
  before moving on.

- **Never rewrite history with raw git inside a jj repo** — no `git reset`,
  `git rebase`, or `git commit` on top of jj-tracked work. jj snapshots the working
  copy into `@`, so a git rewrite underneath it strands that snapshot as a
  *conflicted* orphan: what was a modify becomes modify-vs-absent against the new
  base. Squash with `jj squash`, not `git reset --soft`. Likewise create branches
  with `jj bookmark`: one created by `git` leaves its remote bookmark non-tracking,
  and `jj git push` refuses until `jj bookmark track <name>@origin`.

  Check first, don't assume — and don't trust a repo's own docs on this, since which
  VCS front-end a checkout uses is *my* choice, not a property of the repo. `.jj`
  present and `jj root` resolving is the answer.

- **Never restore files with raw git inside a jj repo** — no `git checkout <path>`,
  `git restore`, `git stash`, or `git reset --hard`. This is a different failure from
  history rewriting above: these overwrite the *working copy* from the git index, and
  in a jj repo the index is not the current change. jj snapshots the working copy into
  `@` and does not keep the index in step, so `git checkout docs` does not "undo my
  edit" — it replaces every file under that path with whatever the index last held,
  which for files created since the last snapshot is *nothing*. They are truncated to
  zero bytes, silently, with a success exit code.

  Undo an edit by rewriting the file, or with `jj restore -c @ <path>`. Recover a
  clobbered one with `jj file show --at-op <op> <path> > <path>`, which changes no
  jj state.

  This gets much sharper with parallel agents: one `git checkout <dir>` destroys every
  in-flight file in that directory, not only your own.

- **Never leave a found issue only in a summary.** Anything wrong I notice along the way —
  a pre-existing bug, a reviewer finding I don't act on, a known limitation I introduce, a
  latent hazard for future work — is either fixed (if cheap and in scope) or filed as a
  ticket in the repo's tracker, linked from the work that found it. Where it constrains an
  existing ticket, comment there instead of opening a new one. "Noted in the final message"
  does not count.

- **Clean up after myself before reporting done.** Remove every scratch file, temp dir,
  container image, volume, background process and throwaway change I created, and restore
  any file I mutated for an experiment. Check for strays (`pgrep`, `docker volume ls`, `ls /tmp`) rather than assuming. Leave alone anything that predates my session.

- **Push bookmark deletions by name** (`jj git push -b <name>` after
  `jj bookmark delete <name>`), never with `jj git push --deleted`. That flag pushes
  *every* bookmark marked deleted, including ones deleted earlier or by another
  session, and silently removes them from the remote.

- Before pushing a branch or opening a PR, run the **same checks CI runs**, not a
  subset. Read `.github/workflows/*` (or the repo's CI config) and run each gate
  locally first. In particular, a formatter *check* (`gofmt -l .`, `prettier --check`, `ruff format --check`, etc.) is a distinct gate from build/lint/test —
  compiling and testing clean does **not** imply formatted. Treat any formatter
  output as a failure to fix before pushing. This is doubly important after
  appending code via heredoc/raw text, which routinely leaves misaligned
  formatting that the formatter would rewrite.

- **A commit that resolves a ticket says so in its message**: `Fixes #N` / `Closes #N`,
  one trailer per issue it closes. The trailer is what makes the merge close the
  ticket — without it a finished, pushed change leaves the tracker lying, and closing
  by hand afterwards also loses the commit↔issue link the forge would have created for
  free. Split work so each commit closes only what it actually finishes.

  If the commit is already pushed, do **not** rewrite history to add it. Comment on
  the issue with a link to the commit, close it explicitly, and say that is what
  happened.

- **Cross-reference with real links.** In commit messages, issue and PR comments and
  docs, an issue, ADR, spec or commit is referenced as a link (or a `#N` the forge
  autolinks), never as a bare name a reader has to go and find. A repo may override
  this for *cross-repo* references — `trunk` deliberately names borrowed terms in bold
  because relative links cannot cross repos and absolute ones do not survive its Notion
  mirror — so check the repo's own `CLAUDE.md` before linking outward.

  **`#N` only autolinks issues and pull requests.** Anything else the forge
  numbers lives on its own sequence, so writing `#N` for it silently produces a
  link to an unrelated issue that happens to hold that number — a wrong link,
  which is worse than the bare name the rule above forbids. The one that bites
  is a **Dependabot alert**: alert 8 is
  `https://github.com/<owner>/<repo>/security/dependabot/8`, and `#8` in the
  same PR body points somewhere else entirely. Same for GHSA identifiers
  (`https://github.com/advisories/GHSA-…`), security advisories, Actions runs
  and Discussions. Before writing `#N`, check the number came from the issue/PR
  sequence; if it did not, write the URL.
