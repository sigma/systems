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
# is swapped for one that opens it (../tuicr-skills).
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
# (programs.herdr.plugins, set by home-modules/programs/tuicr.nix).
{
  lib,
  stdenvNoCC,
  writeShellApplication,
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

    passthru.pluginId = "tuicr";

    meta = {
      description = "herdr plugin opening tuicr in a popup";
      license = lib.licenses.mit;
      platforms = lib.platforms.unix;
    };
  };

in
plugin
