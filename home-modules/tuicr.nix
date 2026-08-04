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
  };
}
