# diffview.nvim configuration
# Cycle through diffs for all modified files, file history, merge tool
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.neovim-ide;
in
{
  config = mkIf cfg.enable {
    programs.nvf.settings.vim.utility.diffview-nvim = {
      enable = true;
      setupOpts = { };
    };

    # Diffview keymaps (Lua module)
    programs.neovim-ide.luaConfigPost."50-diffview-keymaps" = ''
      require('user.diffview').setup()
    '';
  };
}
