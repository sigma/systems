# WezTerm integration
# Smart splits, image protocol, and terminal enhancements
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.neovim-ide;
in
{
  config = mkIf cfg.enable {
    # Add plugins
    programs.nvf.settings.vim.extraPlugins = {
      smart-splits-nvim = {
        package = pkgs.vimPlugins.smart-splits-nvim;
      };
      image-nvim = {
        package = pkgs.vimPlugins.image-nvim;
      };
    };

    # WezTerm integration (Lua module)
    programs.neovim-ide.luaConfigPost."10-wezterm-integration" = ''
      require('user.wezterm').setup()
    '';
  };
}
