# claude-code-statusline — kcchien's two-line Claude Code status line.
#
# Upstream is a single self-contained bash script plus an install.sh that copies
# it to ~/.claude/statusline.sh. We ignore the installer and package the script
# alone, wrapped so it finds jq/git/coreutils without relying on the ambient
# PATH (Claude Code runs the statusLine command with a minimal environment).
#
# The package.json in the repo tree is *not* the program: its react/sharp/
# pptxgenjs deps only build the README's preview images. Nothing at runtime
# needs node, so this is a plain script install rather than buildNpmPackage.
#
# Two upstream behaviours are patched, both because this config also runs on
# Linux and routinely runs several Claude sessions at once:
#
#   - `stat -f %m` is BSD-only, and it does not merely *fail* elsewhere: in GNU
#     coreutils `-f` is `--file-system`, so the same call silently succeeds and
#     prints a multi-line filesystem report into an arithmetic context. Since
#     the wrapper below puts coreutils on PATH, that is the form actually
#     reached here. Ask GNU first, fall back to BSD, and hard-guard the result
#     to digits so a surprising `stat` can never take the statusline down.
#
#   - The git cache path is a single global /tmp file shared by every session.
#     Two sessions in different repos (or different worktrees of one repo)
#     overwrite each other's entry and display the wrong branch for up to the
#     5s cache lifetime; on a multi-user box the first user to create the file
#     also locks everyone else out of it. Key the path by uid and by the
#     session's cwd instead.
{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  jq,
  git,
  coreutils,
}:

stdenvNoCC.mkDerivation {
  pname = "claude-code-statusline";
  # Upstream publishes no tags or releases; pinned to a reviewed commit.
  version = "0-unstable-2026-03-24";

  src = fetchFromGitHub {
    owner = "kcchien";
    repo = "claude-code-statusline";
    rev = "877d24480ca9a37b8eefc0448a6a73a111989b6d";
    hash = "sha256-us6b7kxzAVFoRhiRdTfowTly2EOzMoaB2WEsmXuXvRQ=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  postPatch = ''
    substituteInPlace statusline.sh \
      --replace-fail \
        'local cache_age=$(( $(date +%s) - $(stat -f %m "$GIT_CACHE" 2>/dev/null || echo 0) ))' \
        'local mtime; mtime=$(stat -c %Y "$GIT_CACHE" 2>/dev/null || stat -f %m "$GIT_CACHE" 2>/dev/null || echo 0); case "$mtime" in ""|*[!0-9]*) mtime=0 ;; esac; local cache_age=$(( $(date +%s) - mtime ))' \
      --replace-fail \
        'GIT_CACHE="/tmp/claude-statusline-git-cache"' \
        'GIT_CACHE="''${TMPDIR:-/tmp}/claude-statusline-git-cache-$(id -u)-$(printf %s "''${cwd_full:-}" | cksum | cut -d" " -f1)"'
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 statusline.sh $out/bin/claude-code-statusline
    patchShebangs $out/bin/claude-code-statusline

    wrapProgram $out/bin/claude-code-statusline \
      --prefix PATH : ${
        lib.makeBinPath [
          jq
          git
          coreutils
        ]
      }

    runHook postInstall
  '';

  meta = with lib; {
    description = "Information-dense two-line status line for Claude Code";
    homepage = "https://github.com/kcchien/claude-code-statusline";
    # LICENSE is MIT; package.json's "ISC" is an unedited `npm init` default.
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.unix;
    mainProgram = "claude-code-statusline";
  };
}
