# jj workspaces back Claude Code worktree isolation

Claude Code's `WorktreeCreate`/`WorktreeRemove` hooks let us replace its default
`git worktree` behaviour. We install a **global** pair of hooks (via
`programs.claude-code.settings`) that, when the session repo is a jj repo, create
worktree isolation with `jj workspace add` and tear it down with `jj workspace
forget`; in a plain git repo they fall back to `git worktree add` so unrelated
repos keep working. This makes **jj workspaces the isolation primitive** for both
top-level `--worktree` sessions and subagent `isolation: "worktree"`, because the
hook payload cannot distinguish the two and jj's independent-`@`-per-workspace
model handles parallel working copies at least as well as git worktrees.

## Status

accepted

## Considered Options

The payload gives no field marking subagent-vs-top-level, so per-trigger routing
(git worktrees for subagents, jj for interactive) was not implementable and was
rejected. Pinning new workspaces to `trunk()` was rejected in favour of jj's
default base, keeping the hook a thin translation of git-worktree-at-HEAD
semantics rather than a policy injection. But a jj workspace shares the one
commit graph — it isolates only `@` and the files on disk, not the branch — so a
"thin translation" that stopped at `jj workspace add` left the agent's commits as
anonymous heads that read as loose descendants of main and gave the remove hook
nothing to reconcile. The create hook therefore also runs `jj bookmark create
"$name" -r @` in the new workspace, matching the git fallback's `-b "$name"`; a
pre-existing bookmark of that name is left untouched rather than moved. For the
worktree location we chose
`<repo-root>/.claude/worktrees/<name>` (mirroring Claude Code's own default git
location) over a path under `$HOME`; a nested jj workspace never pollutes the
main *jj* status (jj excludes its own workspaces), and `/.claude` is gitignored
here so the *raw-git* view stays clean too.

## Consequences

- Claude Code's default worktree isolation is a git worktree; with these hooks
  installed, a session or subagent in a jj repo transparently gets a jj workspace
  instead. This is deliberately *not* framed as a repo convention — whether the
  hooks are present is an environment property, so the workflow docs say nothing
  about the mechanism.
- **The remove hook does the actual teardown.** `WorktreeCreate` receives only a
  `name` slug (the hook chooses the path); `WorktreeRemove` receives only
  `worktree_path`, so the remove hook recovers the jj workspace name as its
  basename. Claude Code auto-removes only *its own* git worktrees — a
  hook-created worktree is left on disk otherwise. So the remove hook runs
  `jj workspace forget "$name"` (idempotent) *and* deletes the directory; its
  exit code is ignored by Claude Code.
- **`forget` alone leaks commits, so the remove hook reconciles the bookmark.**
  `jj workspace forget` drops workspace metadata and abandons only the
  workspace's own trailing empty `@` (when eligible) — it never touches the
  commits the workspace produced, which otherwise pile up as anonymous heads. So
  after forgetting, the hook inspects the slug-named bookmark: if it is contained
  in `trunk()` (fast-forward / rebase-merged) the bookmark is redundant and gets
  deleted while the commit stays as trunk history; if it points at an empty
  divergent commit (e.g. the change drained into a mega-merge) it is abandoned;
  otherwise it is unmerged work and is left in place with a warning. This is
  deliberately conservative — it never drops non-empty divergent work, so
  squash-merged commits (whose diff, not identity, landed on trunk) survive here
  and are reconciled by `bw sync` / `jj git fetch --prune` instead. Where
  `trunk()` cannot resolve (no conventional remote) the merged branch simply
  degrades to "kept".
- **Secondary jj workspaces have no own `.git`.** Raw `git rev-parse
  --show-toplevel` from inside such a workspace resolves to the *main* repo, not
  the isolated workspace. jj commands are correctly isolated; git-native tooling
  is not. Agents working in these workspaces must be jj-native.
