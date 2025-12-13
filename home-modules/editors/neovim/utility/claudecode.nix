# Claude Code integration
# AI assistant integration with Claude Code CLI
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
    # Add claudecode.nvim plugin and dependencies
    programs.nvf.settings.vim.extraPlugins = {
      snacks-nvim = {
        package = pkgs.vimPlugins.snacks-nvim;
      };
      claudecode-nvim = {
        package = pkgs.vimPlugins.claudecode-nvim;
        after = [ "snacks-nvim" ];
      };
    };

    # Setup claudecode.nvim
    programs.neovim-ide.luaConfigPost."70-claudecode" = ''
      require('claudecode').setup({
        -- Terminal settings
        terminal = {
          split_side = "right",
          split_width_percentage = 0.35,
          provider = "snacks",
        },

        -- Diff settings
        diff_opts = {
          auto_close_on_accept = true,
          vertical_split = true,
        },
      })
    '';

    # Claude Code keymaps under <leader>a prefix
    programs.nvf.settings.vim.keymaps = [
      # Group prefix
      {
        key = "<leader>a";
        mode = [ "n" ];
        action = "<nop>";
        desc = "AI/Claude Code";
      }
      # Core commands
      {
        key = "<leader>ac";
        mode = [ "n" ];
        action = "<cmd>ClaudeCode<cr>";
        desc = "Toggle Claude";
      }
      {
        key = "<leader>af";
        mode = [ "n" ];
        action = "<cmd>ClaudeCodeFocus<cr>";
        desc = "Focus Claude";
      }
      {
        key = "<leader>ar";
        mode = [ "n" ];
        action = "<cmd>ClaudeCode --resume<cr>";
        desc = "Resume Claude";
      }
      {
        key = "<leader>aC";
        mode = [ "n" ];
        action = "<cmd>ClaudeCode --continue<cr>";
        desc = "Continue Claude";
      }
      {
        key = "<leader>am";
        mode = [ "n" ];
        action = "<cmd>ClaudeCodeSelectModel<cr>";
        desc = "Select Claude model";
      }
      # Context management
      {
        key = "<leader>ab";
        mode = [ "n" ];
        action = "<cmd>ClaudeCodeAdd %<cr>";
        desc = "Add current buffer";
      }
      {
        key = "<leader>as";
        mode = [ "v" ];
        action = "<cmd>ClaudeCodeSend<cr>";
        desc = "Send to Claude";
      }
      # Diff management
      {
        key = "<leader>aa";
        mode = [ "n" ];
        action = "<cmd>ClaudeCodeDiffAccept<cr>";
        desc = "Accept diff";
      }
      {
        key = "<leader>ad";
        mode = [ "n" ];
        action = "<cmd>ClaudeCodeDiffDeny<cr>";
        desc = "Deny diff";
      }
    ];

    # Filetype-specific keymap for tree add (neo-tree, etc.)
    programs.neovim-ide.luaConfigPost."71-claudecode-keymaps" = ''
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "neo-tree", "NvimTree", "oil", "minifiles", "netrw" },
        callback = function()
          vim.keymap.set("n", "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>", {
            buffer = true,
            desc = "Add file to Claude",
          })
        end,
      })
    '';
  };
}
