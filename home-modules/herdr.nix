# herdr — terminal agent multiplexer (https://herdr.dev).
#
# Installs herdr (from the pinned upstream flake input, see
# overlays/default.nix) and renders its TOML configuration to
# ~/.config/herdr/config.toml. The actual values live in the settings loader
# (home-modules/settings/programs/herdr.nix).
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.herdr;
  tomlFormat = pkgs.formats.toml { };
in
{
  options.programs.herdr = {
    enable = mkEnableOption "herdr configuration";

    package = mkPackageOption pkgs "herdr" { };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          keys.prefix = "ctrl+z";
          theme.name = "catppuccin";
        }
      '';
      description = ''
        Configuration written verbatim to {file}`~/.config/herdr/config.toml`.
        See <https://herdr.dev/docs/configuration/> for the full reference, or
        run `herdr --default-config` for the annotated defaults.
      '';
    };

    plugins = mkOption {
      type = types.attrsOf types.path;
      default = { };
      example = literalExpression "{ tuicr = pkgs.local.herdr-tuicr-plugin; }";
      description = ''
        herdr plugins to keep linked, keyed by the plugin id declared in each
        directory's `herdr-plugin.toml`. herdr keeps its plugin registry in
        {file}`~/.config/herdr/plugins.json`, which it rewrites itself, so
        these can't be written as config files: activation runs
        `herdr plugin link` for every entry whose registered root differs,
        and unlinks any other plugin rooted in the Nix store (i.e. one this
        option used to declare). See <https://herdr.dev/docs/plugins/>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."herdr/config.toml".source = tomlFormat.generate "herdr-config.toml" cfg.settings;

    # `herdr plugin link` registers a plugin whether or not a server is running
    # and a running server picks the change up immediately, so this needs no
    # reload step. Re-linking the same id replaces the previous registration.
    # herdr snapshots the manifest into plugins.json at link time, and every
    # rebuild that touches a plugin yields a new store path, so comparing the
    # registered root against the wanted one is enough to know when to relink.
    home.activation.herdrPlugins = mkIf (cfg.plugins != { }) (
      hm.dag.entryAfter [ "writeBoundary" ] ''
        herdr=${getExe cfg.package}
        registry="${config.xdg.configHome}/herdr/plugins.json"
        have='[]'
        [ ! -s "$registry" ] || have=$(cat "$registry")
        wanted=${escapeShellArg (builtins.toJSON (mapAttrs (_: root: "${root}") cfg.plugins))}
        # Plugins declared here whose registered root is not the wanted one.
        ${getExe pkgs.jq} -nr --argjson have "$have" --argjson wanted "$wanted" '
          ([$have[] | {key: .plugin_id, value: .plugin_root}] | from_entries) as $roots
          | $wanted | to_entries[] | select($roots[.key] != .value) | .value
        ' | while IFS= read -r root; do
          echo "Linking herdr plugin $root"
          run "$herdr" plugin link "$root" > /dev/null
        done
        # Store-rooted plugins no longer declared here: previously ours.
        ${getExe pkgs.jq} -nr --argjson have "$have" --argjson wanted "$wanted" '
          $have[] | select(.source.kind == "local")
          | select(.plugin_root | startswith("${builtins.storeDir}/"))
          | select($wanted[.plugin_id] == null) | .plugin_id
        ' | while IFS= read -r id; do
          echo "Unlinking herdr plugin $id"
          run "$herdr" plugin unlink "$id" > /dev/null
        done
      ''
    );
  };
}
