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
    # Add claudecode.nvim plugin
    programs.nvf.settings.vim.extraPlugins = {
      claudecode-nvim = {
        package = pkgs.vimPlugins.claudecode-nvim;
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
      {
        key = "<leader>ac";
        mode = [ "n" ];
        action = "<cmd>ClaudeCode<cr>";
        desc = "Toggle Claude Code";
      }
      {
        key = "<leader>af";
        mode = [ "n" ];
        action = "<cmd>ClaudeCodeFocus<cr>";
        desc = "Focus Claude Code";
      }
      {
        key = "<leader>as";
        mode = [ "v" ];
        action = "<cmd>ClaudeCodeSend<cr>";
        desc = "Send selection to Claude";
      }
      {
        key = "<leader>aa";
        mode = [ "n" ];
        action = "<cmd>ClaudeCodeAdd<cr>";
        desc = "Add file to Claude context";
      }
      {
        key = "<leader>aA";
        mode = [ "n" ];
        action = "<cmd>ClaudeCodeDiffAccept<cr>";
        desc = "Accept Claude diff";
      }
      {
        key = "<leader>aD";
        mode = [ "n" ];
        action = "<cmd>ClaudeCodeDiffDeny<cr>";
        desc = "Deny Claude diff";
      }
    ];
  };
}
