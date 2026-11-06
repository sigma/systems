# tuicr's agent skills, with reviews opened as floating panes.
#
# The toolbox's tuicr-skills bundle, with two wrappers swapped or added and
# SKILL.md adjusted to match (SKILL.md.sed):
#
#   - tuicr-wrapper-herdr.sh replaces upstream's split-pane one with a herdr
#     popup, opened through the `tuicr` herdr plugin (../herdr-tuicr-plugin).
#   - tuicr-wrapper-rex.sh opens a Rex floating pane. The pinned release has
#     no Rex wrapper; upstream main's splits the agent's block and returns at
#     once, while this one blocks until tuicr exits, like the herdr one.
#
# Both keep the blocking-wrapper contract (`<wrapper> /path -- <scope>`, the
# review printed between TUICR INSTRUCTIONS markers). The build fails when
# upstream changes under the patch: the herdr wrapper disappears, a Rex wrapper
# appears (adopt or replace it then), or the SKILL.md edits stop applying.
{
  runCommand,
  toolbox,
}:
runCommand "${toolbox.tuicr-skills.name}-floating"
  {
    inherit (toolbox.tuicr-skills) meta;
  }
  ''
    cp -r ${toolbox.tuicr-skills} $out
    chmod -R u+w $out
    skill=$out/skills/tuicr
    [ -f "$skill/tuicr-wrapper-herdr.sh" ] || {
      echo "tuicr-skills no longer ships tuicr-wrapper-herdr.sh; update this package" >&2
      exit 1
    }
    if [ -e "$skill/tuicr-wrapper-rex.sh" ] || grep -q 'tuicr-wrapper-rex' "$skill/SKILL.md"; then
      echo "tuicr-skills now ships a Rex wrapper; update this package" >&2
      exit 1
    fi
    install -m755 ${./tuicr-wrapper-herdr.sh} "$skill/tuicr-wrapper-herdr.sh"
    install -m755 ${./tuicr-wrapper-rex.sh} "$skill/tuicr-wrapper-rex.sh"
    sed -i -E -f ${./SKILL.md.sed} "$skill/SKILL.md"
    for marker in 'Herdr popup' 'tuicr-wrapper-rex.sh /path/to/repo -- <scope>' \
      '<skill-directory>/tuicr-wrapper-rex.sh' 'Rex floating pane' '^Rex:$' \
      'Zellij, Herdr, and Rex wrappers wait' 'Zellij/Herdr/Rex available' \
      'Zellij, Herdr, or Rex when'; do
      grep -q -- "$marker" "$skill/SKILL.md" || {
        echo "SKILL.md patch did not apply ($marker); upstream text changed" >&2
        exit 1
      }
    done
  ''
