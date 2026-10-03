# tuicr — code-review TUI (https://github.com/agavra/tuicr).
#
# tuicr itself is installed via home.packages (home-modules/default.nix). This
# module only renders its TOML configuration to ~/.config/tuicr/config.toml.
# The actual values live in the settings loader
# (home-modules/settings/programs/tuicr.nix).
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.tuicr;
  tomlFormat = pkgs.formats.toml { };
in
{
  options.programs.tuicr = {
    enable = mkEnableOption "tuicr configuration";

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          theme = "catppuccin-frappe";
          leader = ",";
        }
      '';
      description = ''
        Configuration written verbatim to {file}`~/.config/tuicr/config.toml`.
        See <https://github.com/agavra/tuicr/blob/main/docs/CONFIG.md>.
      '';
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile."tuicr/config.toml".source = tomlFormat.generate "tuicr-config.toml" cfg.settings;

    # tuicr's agent skills teach agents to drive the review TUI. Under herdr
    # the bundle's herdr wrapper is swapped for one that opens tuicr in a
    # herdr popup, which herdr only exposes to scripts as a plugin pane — so
    # the plugin and the patched skills ship together, from one package
    # (overlays/pkg/local/herdr-tuicr-plugin).
    programs.herdr.plugins = mkIf config.programs.herdr.enable {
      tuicr = pkgs.local.herdr-tuicr-plugin;
    };
    programs.agentSkills.plugins = [
      (
        if config.programs.herdr.enable then
          pkgs.local.herdr-tuicr-plugin.skills
        else
          pkgs.toolbox.tuicr-skills
      )
    ];
  };
}
