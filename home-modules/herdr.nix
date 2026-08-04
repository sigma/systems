# herdr — terminal agent multiplexer (https://herdr.dev).
#
# herdr itself is installed via Homebrew (darwin-modules/apps/ai.nix). This
# home-manager module only renders its TOML configuration to
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
  };

  config = mkIf cfg.enable {
    xdg.configFile."herdr/config.toml".source = tomlFormat.generate "herdr-config.toml" cfg.settings;
  };
}
