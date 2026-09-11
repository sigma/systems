# Refuse to start zile when there is no controlling terminal.
#
# zile is a curses editor; with no terminal to drive it, it does not exit — it
# spins in its input loop and burns a full core until killed. That happens
# routinely when an AI agent trips an interactive VCS operation (`git commit`
# without -m, `git rebase -i`, `jj describe`), because $EDITOR is inherited by
# the agent's non-interactive shell.
#
# The guard lives on the *package* rather than on `programs.zile.package` so it
# also covers consumers that reference `pkgs.zile` directly (the fzf ctrl-o
# binding in settings/programs/fzf.nix) and any environment where our session
# variables were not inherited.
#
# Requiring both stdin and stdout to be a tty is not a heuristic: that is the
# precondition for a curses app to function at all. Callers that legitimately
# open an editor (a terminal, fzf's `execute()`) hand the child the terminal;
# callers that spin it up from a pipe never had a usable session to begin with.
#
# This is the unconditional backstop. The agent-facing half — pointing
# EDITOR/GIT_EDITOR/&c. at `local.no-editor` so the failure is actionable
# instead of merely fatal — lives in settings/programs/claude-code.nix.
final: prev:
let
  guard = ''
    if [ ! -t 0 ] || [ ! -t 1 ]; then
      echo "zile: refusing to start without a controlling terminal." >&2
      echo "zile: (a non-interactive zile spins on a core until killed)" >&2
      echo "zile: if a VCS command brought you here, use a non-interactive form:" >&2
      echo "zile:   git commit -m MSG | git commit --no-edit | git rebase --no-edit" >&2
      echo "zile:   jj describe -m MSG | jj commit -m MSG" >&2
      exit 1
    fi
  '';
in
{
  zile = prev.symlinkJoin {
    name = "${prev.zile.name}-tty-guarded";
    paths = [ prev.zile ];
    nativeBuildInputs = [ prev.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/zile --run ${prev.lib.escapeShellArg guard}
    '';
    inherit (prev.zile) meta;
  };
}
