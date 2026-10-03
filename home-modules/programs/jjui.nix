# jjui — TUI for jj (https://idursun.github.io/jjui/).
#
# home-manager's programs.jjui module already renders config.toml, config.lua
# and Lua plugins into programs.jjui.configDir; this adds what it lacks:
#
# - `themes`: directories of `<name>.toml` theme files, merged into
#   `<configDir>/themes/`, where jjui resolves `ui.theme = "<name>"`.
# - catppuccin integration, same shape as hunk.nix: when catppuccin is enabled
#   globally, ship the tinted-jjui collection and default `ui.theme` to the
#   base24 variant of the selected flavor.

{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.jjui;
in
{
  options.programs.jjui.themes = mkOption {
    type = types.listOf types.path;
    default = [ ];
    example = literalExpression ''[ "''${pkgs.local.tinted-jjui}/share/jjui/themes" ]'';
    description = ''
      Directories of theme files, merged into {file}`<configDir>/themes/`;
      select one with `settings.ui.theme = "<name>"`.
      See <https://idursun.github.io/jjui/customization/themes/>.
    '';
  };

  config = lib.mkMerge [
    # jjui is installed everywhere via the vcs-toolchain bundle, so the config is
    # enabled everywhere too (matches tuicr).
    {
      programs.jjui = {
        enable = lib.mkDefault (true);

        # jjui ships in the toolbox's vcs-toolchain bundle (home-modules/content/base.nix);
        # installing it again would collide on `bin/jjui`.
        package = null;

        # Fuzzy matching for the `:` (exec) and `$` prompts' suggestions.
        settings.suggest.exec.mode = "fuzzy";
      };
    }

    (mkIf cfg.enable (mkMerge [
      {
        home.file = listToAttrs (
          imap0 (i: dir: {
            name = "jjui-themes-${toString i}";
            value = {
              target = "${cfg.configDir}/themes";
              source = dir;
              recursive = true;
            };
          }) cfg.themes
        );
      }

      (mkIf config.catppuccin.enable {
        programs.jjui.themes = [ "${pkgs.local.tinted-jjui}/share/jjui/themes" ];
        # base24 rather than base16: it extends the scheme with eight more slots,
        # so the template maps more UI roles to distinct palette colours (both
        # are plain truecolor hex files; this is not about terminal support).
        programs.jjui.settings.ui.theme = mkDefault "base24-catppuccin-${config.catppuccin.flavor}";
      })
    ]))
  ];
}
