# A stand-in for $EDITOR in non-interactive agent sessions.
#
# It reads nothing, blocks on nothing, and always fails. Pointing the whole
# editor-variable family at it removes the *possibility* of an interactive
# editor in a session that has no human to drive one, and turns what would have
# been a hang into an immediate, actionable error.
#
# Exiting non-zero rather than no-opping is deliberate. `EDITOR=true` looks
# equivalent but is worse: git aborts on the resulting empty message, while
# `jj describe` happily *accepts* the empty buffer and silently blanks the
# change description. A hard failure makes both abort cleanly.
{
  writeShellApplication,
  lib,
}:
writeShellApplication {
  name = "no-editor";
  text = ''
    exec >&2
    echo "no-editor: interactive editors are disabled in agent sessions."
    echo
    echo "Something invoked \$EDITOR (argv: $*)."
    echo "Re-run the command in a form that needs no editor:"
    echo "  git commit -m MSG        git commit --no-edit"
    echo "  git rebase --no-edit     GIT_SEQUENCE_EDITOR=: git rebase -i"
    echo "  git tag -m MSG           git merge --no-edit"
    echo "  jj describe -m MSG       jj commit -m MSG"
    echo
    echo "If the change genuinely requires a human at a terminal, hand it back"
    echo "to the user rather than trying to drive an editor."
    exit 1
  '';

  meta = {
    description = "Failing \$EDITOR stand-in for non-interactive agent sessions";
    mainProgram = "no-editor";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
