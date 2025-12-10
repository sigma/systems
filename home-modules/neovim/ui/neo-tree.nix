# Neo-tree file explorer configuration
# LazyVim-style file tree on the left
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
    programs.nvf.settings.vim.filetree.neo-tree = {
      enable = true;

      setupOpts = {
        # Position on left side
        position = "left";

        # Enable features
        enable_git_status = true;
        enable_diagnostics = true;
        enable_modified_markers = true;

        # Replace netrw
        filesystem = {
          hijack_netrw_behavior = "open_default";
          follow_current_file = {
            enabled = true;
          };
          use_libuv_file_watcher = true;
        };

        # Window settings
        window = {
          width = 35;
          mappings = {
            "<space>" = "none"; # Don't conflict with leader
          };
        };

        # Default component configs
        default_component_configs = {
          indent = {
            with_markers = true;
            with_expanders = true;
          };
          git_status = {
            symbols = {
              added = "";
              modified = "";
              deleted = "";
              renamed = "󰁕";
              untracked = "";
              ignored = "";
              staged = "";
              conflict = "";
            };
          };
        };
      };
    };

    # Neo-tree keymaps
    programs.nvf.settings.vim.keymaps = [
      {
        key = "<leader>e";
        mode = [ "n" ];
        action = "<cmd>Neotree toggle<cr>";
        desc = "Toggle file explorer";
      }
      {
        key = "<leader>E";
        mode = [ "n" ];
        action = "<cmd>Neotree reveal<cr>";
        desc = "Reveal current file in explorer";
      }
    ];
  };
}
