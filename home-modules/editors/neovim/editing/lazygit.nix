# lazygit.nvim integration
# Toggle lazygit in a floating terminal window
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
    # Add lazygit.nvim plugin (no setup function, uses vim globals)
    programs.nvf.settings.vim.extraPlugins = {
      lazygit-nvim = {
        package = pkgs.vimPlugins.lazygit-nvim;
      };
    };

    # Configure lazygit.nvim (Lua module)
    programs.neovim-ide.luaConfigPost."55-lazygit" = ''
      require('user.lazygit').setup()
    '';
  };
}
