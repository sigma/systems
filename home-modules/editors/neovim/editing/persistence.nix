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
    # persistence.nvim - lazy load on file read (to capture session)
    programs.nvf.settings.vim.lazy.plugins = {
      "persistence.nvim" = {
        package = pkgs.vimPlugins.persistence-nvim;
        event = [ "BufReadPre" ];
        after = ''
          require('persistence').setup({
            dir = vim.fn.expand(vim.fn.stdpath("state") .. "/sessions/"),
            need = 1,
            branch = true,
          })

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
