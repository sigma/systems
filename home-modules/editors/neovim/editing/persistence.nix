# persistence.nvim configuration
# Automated session management
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
    programs.nvf.settings.vim.extraPlugins = {
      persistence-nvim = {
        package = pkgs.vimPlugins.persistence-nvim;
        setup = ''
          require('persistence').setup({
            -- Directory where session files are saved
            dir = vim.fn.expand(vim.fn.stdpath("state") .. "/sessions/"),
            -- Minimum number of file buffers to save
            need = 1,
            -- Branch specific sessions
            branch = true,
          })

          -- LazyVim-style keymaps
          vim.keymap.set("n", "<leader>qs", function()
            require("persistence").load()
          end, { desc = "Restore session" })

          vim.keymap.set("n", "<leader>qS", function()
            require("persistence").select()
          end, { desc = "Select session" })

          vim.keymap.set("n", "<leader>ql", function()
            require("persistence").load({ last = true })
          end, { desc = "Restore last session" })

          vim.keymap.set("n", "<leader>qd", function()
            require("persistence").stop()
          end, { desc = "Don't save current session" })
        '';
      };
    };
  };
}
