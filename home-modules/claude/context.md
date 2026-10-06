# Personal engineering discipline (global)

Principles that hold across all my projects. Anything specific to one codebase
belongs in that repo's `./CLAUDE.md`.

## Working with me

- When I correct you or state a preference, propose an edit and wait for my
  approval of the diff:
  - **General principle** → this file (`~/.config/nix/home-modules/claude/context.md`,
    symlinked as `~/.claude/CLAUDE.md`), as its own jj change (`jj new` first).
  - **Project-specific** → the repo's `./CLAUDE.md`.

  If the rule is mechanically checkable, also propose a lint, test or hook: prose
  only influences, a check enforces.
- When my preference conflicts with a constraint you introduced (in a
  recommendation, spec or decision), name the constraint and ask whether it still
  stands. Don't quietly work around me.

## Code

- No regex-based parsers. Use a real tokenizer, parser or grammar.
- Import a dependency's constants; don't copy them as literals. A copy is a second
  source of truth, and a test guarding it only proves the copy matches itself.
- A library that mirrors the wire/file format of a pinned binary is pinned to the
  **same exact version**, never a range. Bump them together.
- Don't reach collaborators through process-global state: no
  `os.Setenv`/`t.Setenv`, `os.Chdir`/`t.Chdir`, or libraries reading env/cwd.
  Inject via a parameter so tests stay parallel-safe. Setting
  `cmd.Env`/`cmd.Dir` on a child process is fine.
- Never build a release artifact locally to get round a CI that can't build
  it. Fix the CI: artifacts others pin need inspectable provenance.

## Nix

- Evaluate the narrowest attribute that answers the question
  (`.#homeConfigurations.<host>.config.programs.foo.enable`), never a whole closure
  to read one value.
- `--quiet`, plus `--no-link` on builds. Filter inside Nix (`--raw`, `--json --apply`),
  not via `grep`/`jq`; send full logs to `/tmp/nix-out.txt` and read the tail.
- Ask before rebuilding a full system or home closure. A package or narrow attribute
  needs no permission.

## Formatting

Format only the files you touched (`nixfmt <file>`,
`prettier --write <files>`). Run repo-wide formatters (`nix fmt`, `treefmt`,
`prettier .`) only when I ask or CI gates on them, and in check mode first.

## jj

A repo is jj if `.jj` exists and `jj root` resolves. Don't trust repo docs on this;
the front-end is my choice.

- Anchor paths to `jj root` (`git rev-parse --show-toplevel` outside jj). In a jj
  workspace, git resolves to the *main* repo, not yours.
- `jj new` before each unit of work, and again after describing a finished
  one. Edits land silently in `@`, so skipping it amends whatever change is
  current. If `@` has a description or `jj st` shows changes you didn't make,
  `jj new` first.
- Abandon throwaway changes (repros, red-gate proofs) once they've served; never
  leave `@` on one. Confirm `jj st` is clean.
- No raw-git writes: no `git commit`/`rebase`/`reset`/`checkout <path>`/
  `restore`/`stash`. They desync from jj's snapshot of `@`: rewrites strand
  conflicted orphans, and restores can silently truncate files to zero bytes,
  including parallel agents' in-flight work. Use `jj squash`,
  `jj restore -c @ <path>`, and `jj bookmark` (git-created branches aren't
  tracked). Recover a clobbered file with
  `jj file show --at-op <op> <path> > <path>`.
- Push bookmark deletions by name (`jj git push -b <name>`), never
  `--deleted`: it pushes every pending deletion, including other sessions'.

## Finishing work

- Before pushing, run every gate CI runs (read `.github/workflows/*`), formatter
  checks included. Clean build and tests don't imply formatted.
- Never leave a found issue only in a summary: fix it if cheap and in scope, else
  file a ticket linked from the work (or comment on an existing one it constrains).
- Clean up everything you created (scratch files, temp dirs, images, volumes,
  processes, throwaway changes) and restore files you mutated. Check for strays
  (`pgrep`, `docker volume ls`, `ls /tmp`); leave pre-existing things alone.
- A commit that resolves a ticket carries one `Fixes #N` per issue, and closes only
  what it finishes. If it's already pushed, don't rewrite: comment with the commit
  link, close the issue by hand, and say so.
- Reference issues, ADRs, specs and commits as links, never bare names (a
  repo's `CLAUDE.md` may override this for cross-repo refs). `#N` only
  autolinks issues and PRs; Dependabot alerts, GHSAs, advisories, Actions runs
  and Discussions need full URLs.
