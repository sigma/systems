# agy-hud — status-line HUD for Google's Antigravity CLI (`agy`).
#
# Enabled by darwin-modules/apps/antigravity-cli.nix, which is what installs
# the CLI itself; the package lives in overlays/pkg/local/agy-hud.nix.
{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.agy-hud;
  pluginDir = ".gemini/config/plugins/agy-hud";
in
{
  options.programs.agy-hud = {
    enable = mkEnableOption "agy-hud status line for the Antigravity CLI";

    package = mkOption {
      type = types.package;
      default = pkgs.local.agy-hud;
      defaultText = literalExpression "pkgs.local.agy-hud";
      description = "The agy-hud package providing the plugin root and CLI.";
    };
  };

  config = mkIf cfg.enable {
    # Upstream's install path is `agy plugin install <dir>`, which *copies* a
    # plugin archive into ~/.gemini/config/plugins. Symlinking the store's
    # plugin root there gives the same layout declaratively, so upgrades follow
    # the package instead of needing a re-install.
    home.file.${pluginDir}.source = "${cfg.package}/share/agy-hud";

    # `agy-hud version` / `agy-hud quota refresh`, which upstream leaves to a
    # bare `node <plugin-root>/dist/agy-hud.js`.
    home.packages = [ cfg.package ];

    # Wiring the hook is a separate step from installing the plugin: agy keeps
    # `statusLine.command` in its own settings.json, a file the CLI rewrites at
    # runtime (trusted workspaces, model choice), so it cannot be managed
    # declaratively — patch just that key and leave the rest alone. This stands
    # in for the `/statusline <hook>` slash command the README asks for.
    #
    # `statusLine.type` is deliberately untouched: it is "" on a working
    # built-in status line and nothing documents what a custom command should
    # set it to. If the HUD does not appear, run
    # `/statusline ~/.gemini/config/plugins/agy-hud/hooks/status-line.sh` once
    # inside agy; this script then keeps that path current across upgrades.
    home.activation.agyHudStatusLine = hm.dag.entryAfter [ "writeBoundary" ] ''
      settings="$HOME/.gemini/antigravity-cli/settings.json"
      hook="$HOME/${pluginDir}/hooks/status-line.sh"
      current=""
      if [ -e "$settings" ]; then
        current="$(${pkgs.jq}/bin/jq -r '.statusLine.command // ""' "$settings")"
      fi
      if [ "$current" != "$hook" ]; then
        echo "Pointing agy's status line at agy-hud"
        run ${pkgs.bash}/bin/bash -c '
          set -eu
          settings="$1"; hook="$2"
          ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$settings")"
          [ -e "$settings" ] || echo "{}" > "$settings"
          ${pkgs.jq}/bin/jq --arg hook "$hook" \
            ".statusLine.command = \$hook | .statusLine.enabled = true" \
            "$settings" > "$settings.agy-hud.tmp"
          ${pkgs.coreutils}/bin/mv "$settings.agy-hud.tmp" "$settings"
        ' -- "$settings" "$hook"
      fi
    '';
  };
}
