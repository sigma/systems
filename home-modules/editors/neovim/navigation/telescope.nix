# Telescope fuzzy finder configuration
# LazyVim-style keymaps for finding files, grep, buffers, etc.
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
    programs.nvf.settings.vim.telescope = {
      enable = true;

      setupOpts = {
        defaults = {
          prompt_prefix = " ";
          selection_caret = " ";
          layout_strategy = "horizontal";
          layout_config = {
            horizontal = {
              prompt_position = "top";
              preview_width = 0.55;
            };
            width = 0.87;
            height = 0.80;
          };
          sorting_strategy = "ascending";
          winblend = 0;
        };
      };

      # LazyVim-style keymaps
      mappings = {
        # Find
        findFiles = "<leader>ff";
        liveGrep = "<leader>fg";
        buffers = "<leader>fb";
        helpTags = "<leader>fh";
        resume = "<leader>fr";
        # Git
        gitFiles = "<leader>gf";
        gitCommits = "<leader>gc";
        gitBranches = "<leader>gb";
        gitStatus = "<leader>gs";
        # LSP
        lspDocumentSymbols = "<leader>ss";
        lspWorkspaceSymbols = "<leader>sS";
        diagnostics = "<leader>sd";
      };
    };

    # Additional Telescope keymaps
    programs.nvf.settings.vim.keymaps = [
      {
        key = "<leader><space>";
        mode = [ "n" ];
        action = "<cmd>Telescope find_files<cr>";
        desc = "Find files";
      }
      {
        key = "<leader>/";
        mode = [ "n" ];
        action = "<cmd>Telescope live_grep<cr>";
        desc = "Grep in project";
      }
      {
        key = "<leader>,";
        mode = [ "n" ];
        action = "<cmd>Telescope buffers show_all_buffers=true<cr>";
        desc = "Switch buffer";
      }
      {
        key = "<leader>:";
        mode = [ "n" ];
        action = "<cmd>Telescope command_history<cr>";
        desc = "Command history";
      }
      {
        key = "<leader>sg";
        mode = [ "n" ];
        action = "<cmd>Telescope live_grep<cr>";
        desc = "Grep";
      }
      {
        key = "<leader>sw";
        mode = [ "n" ];
        action = "<cmd>Telescope grep_string<cr>";
        desc = "Grep word under cursor";
      }
      {
        key = "<leader>sr";
        mode = [ "n" ];
        action = "<cmd>Telescope resume<cr>";
        desc = "Resume last search";
      }
    ];
  };
}
