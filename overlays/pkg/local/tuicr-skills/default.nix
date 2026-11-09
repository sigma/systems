# tuicr's agent skills, with reviews opened in a Rex floating pane.
#
# The toolbox's tuicr-skills bundle, with tuicr-wrapper-rex.sh added and
# SKILL.md adjusted to match (SKILL.md.sed). The pinned release has no Rex
# wrapper; upstream main's splits the agent's block and returns at once, while
# this one blocks until tuicr exits.
#
# It keeps the blocking-wrapper contract (`<wrapper> /path -- <scope>`, the
# review printed between TUICR INSTRUCTIONS markers). The build fails when
# upstream changes under the patch: a Rex wrapper appears (adopt or replace it
# then), or the SKILL.md edits stop applying.
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
    if [ -e "$skill/tuicr-wrapper-rex.sh" ] || grep -q 'tuicr-wrapper-rex' "$skill/SKILL.md"; then
      echo "tuicr-skills now ships a Rex wrapper; update this package" >&2
      exit 1
    fi
    install -m755 ${./tuicr-wrapper-rex.sh} "$skill/tuicr-wrapper-rex.sh"
    sed -i -E -f ${./SKILL.md.sed} "$skill/SKILL.md"
    for marker in 'tuicr-wrapper-rex.sh /path/to/repo -- <scope>' \
      '<skill-directory>/tuicr-wrapper-rex.sh' 'Rex floating pane' '^Rex:$' \
      'Zellij, Herdr, and Rex wrappers wait' 'Zellij/Herdr/Rex available' \
      'Zellij, Herdr, or Rex when'; do
      grep -q -- "$marker" "$skill/SKILL.md" || {
        echo "SKILL.md patch did not apply ($marker); upstream text changed" >&2
        exit 1
      }
    done
  ''
