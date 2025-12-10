# LuaSnip and snippets configuration
# Snippet engine with friendly-snippets collection
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
    programs.nvf.settings.vim.snippets.luasnip = {
      enable = true;

      # Load friendly-snippets (VS Code compatible snippets)
      providers = [ "friendly-snippets" ];

      # Enable auto-snippets
      setupOpts = {
        enable_autosnippets = true;
        history = true;
      };
    };

    # Add snippet placeholder navigation keymaps
    # These work alongside nvim-cmp's Tab/S-Tab for smart behavior
    programs.neovim-ide.luaConfigPost."40-snippet-keymaps" = ''
      -- Snippet placeholder navigation (LazyVim-style)
      -- Tab jumps forward in snippet, S-Tab jumps backward
      local luasnip = require("luasnip")

      vim.keymap.set({ "i", "s" }, "<Tab>", function()
        if luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        else
          -- Fall back to regular Tab (completion handled by nvim-cmp)
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
        end
      end, { silent = true, desc = "Expand snippet or jump forward" })

      vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
        if luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          -- Fall back to regular S-Tab
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<S-Tab>", true, false, true), "n", false)
        end
      end, { silent = true, desc = "Jump backward in snippet" })

      -- <C-l> to select choice node (for snippets with multiple options)
      vim.keymap.set({ "i", "s" }, "<C-l>", function()
        if luasnip.choice_active() then
          luasnip.change_choice(1)
        end
      end, { silent = true, desc = "Select next snippet choice" })
    '';
  };
}
