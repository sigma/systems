# herdr — terminal agent multiplexer (https://herdr.dev).
#
# On darwin, herdr itself is installed via Homebrew (darwin-modules/apps/ai.nix),
# so `package` is null there and this module only renders herdr's TOML
# configuration to ~/.config/herdr/config.toml. Elsewhere (NixOS) `package` is
# set and herdr lands in home.packages too. The actual values live in the
# settings loader (home-modules/settings/programs/herdr.nix).
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

    package = mkOption {
      type = types.nullOr types.package;
      default = null;
      example = literalExpression "pkgs.master.herdr";
      description = ''
        The herdr package to install, or `null` to only manage the
        configuration (used on darwin, where herdr comes from Homebrew).
      '';
    };

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
    home.packages = optional (cfg.package != null) cfg.package;

    xdg.configFile."herdr/config.toml".source = tomlFormat.generate "herdr-config.toml" cfg.settings;
  };
}
