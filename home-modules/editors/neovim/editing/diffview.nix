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

    # Add keymaps for diffview
    programs.neovim-ide.luaConfigPost."50-diffview-keymaps" = ''
      -- Diffview keymaps (LazyVim-style under <leader>g prefix)
      vim.keymap.set("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "Diffview Open" })
      vim.keymap.set("n", "<leader>gD", "<cmd>DiffviewClose<cr>", { desc = "Diffview Close" })
      vim.keymap.set("n", "<leader>gH", "<cmd>DiffviewFileHistory<cr>", { desc = "Diffview File History" })
      vim.keymap.set("n", "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", { desc = "Diffview Current File History" })
    '';
  };
}
