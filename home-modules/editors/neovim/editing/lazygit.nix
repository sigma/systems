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

    # Configure lazygit.nvim via globals and add keymaps
    programs.neovim-ide.luaConfigPost."55-lazygit" = ''
      -- Lazygit configuration (via globals)
      vim.g.lazygit_floating_window_use_plenary = 0
      vim.g.lazygit_floating_window_border_chars = {'╭','─', '╮', '│', '╯','─', '╰', '│'}

      -- Lazygit keymaps (LazyVim-style)
      vim.keymap.set("n", "<leader>gg", "<cmd>LazyGit<cr>", { desc = "LazyGit" })
      vim.keymap.set("n", "<leader>gG", "<cmd>LazyGitCurrentFile<cr>", { desc = "LazyGit Current File" })
    '';
  };
}
