# tuicr in a herdr popup.
#
# tuicr's skill ships a herdr wrapper that splits the agent's pane and runs
# the review TUI there. herdr also has popups — the floating, session-modal
# terminals bound under `[[keys.command]] type = "popup"` — but nothing in its
# CLI can open one of *those* on demand: `command.invoke` wants an opaque
# command id from the GUI client-shell projection. The one scriptable route is
# a plugin pane declared with `placement = "popup"`, which `herdr plugin pane
# open --plugin tuicr --entrypoint review --cwd … --env …` opens from any
# script. So the popup is packaged as a herdr plugin, and the skill's wrapper
# is swapped for one that opens it (see `skills` below).
#
# A popup is not a herdr pane: no pane ID, no `pane wait-output`, and the
# manifest command is a shell-less argv array. Hence the split into two
# scripts: tuicr-wrapper-herdr.sh (agent side; opens the popup, passes cwd and
# tuicr args through `--cwd`/`--env`, polls a status file) and tuicr-popup.sh
# (popup side; runs tuicr, writes the status file on exit).
#
# herdr keeps its plugin registry in ~/.config/herdr/plugins.json, a file it
# rewrites itself, so the plugin can't be dropped in as a config file; the
# home-manager module registers `$out` with `herdr plugin link` at activation
# (programs.herdr.plugins, home-modules/herdr.nix).
{
  lib,
  stdenvNoCC,
  runCommand,
  writeShellApplication,
  toolbox,
}:
let
  popup = writeShellApplication {
    name = "tuicr-popup";
    text = builtins.readFile ./tuicr-popup.sh;
    # tuicr-popup.sh reads its inputs from the environment, so shellcheck's
    # unassigned-variable warnings are expected.
    excludeShellChecks = [ "SC2154" ];
  };

  plugin = stdenvNoCC.mkDerivation {
    pname = "herdr-tuicr-plugin";
    version = "0.1.0";

    src = ./.;

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      substitute herdr-plugin.toml $out/herdr-plugin.toml \
        --replace-fail '@popup@' '${lib.getExe popup}'
      runHook postInstall
    '';

    passthru = {
      inherit skills;
      pluginId = "tuicr";
    };

    meta = {
      description = "herdr plugin opening tuicr in a popup";
      license = lib.licenses.mit;
      platforms = lib.platforms.unix;
    };
  };

  # The toolbox's tuicr-skills bundle with the herdr wrapper replaced by the
  # popup one, and SKILL.md's Herdr notes adjusted to match: nothing else in
  # the skill changes, so the agent-facing contract (`tuicr-wrapper-herdr.sh
  # /path -- <scope>`, blocking until exit) is untouched.
  skills =
    runCommand "${toolbox.tuicr-skills.name}-herdr-popup"
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
        install -m755 ${./tuicr-wrapper-herdr.sh} "$skill/tuicr-wrapper-herdr.sh"
        sed -i -E -f ${./SKILL.md.sed} "$skill/SKILL.md"
        grep -q 'Herdr popup' "$skill/SKILL.md" || {
          echo "SKILL.md patch did not apply; upstream text changed" >&2
          exit 1
        }
      '';
in
plugin
