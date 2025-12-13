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

    # Custom root name formatter for neo-tree
    programs.neovim-ide.luaConfigPost."40-neotree-root" = ''
      -- Create a custom component for the root folder name with colored org
      local neo_tree_components = require('neo-tree.sources.common.components')
      local highlights = require('neo-tree.ui.highlights')
      local original_name = neo_tree_components.name

      neo_tree_components.name = function(config, node, state)
        local result = original_name(config, node, state)
        -- Check if this is the root node
        if node:get_depth() == 1 and node.type == 'directory' then
          -- Match ~/src/github.com/ORG/PROJECT or similar
          local org, project = node.path:match('.*/src/[^/]+/([^/]+)/([^/]+)$')
          if org and project then
            -- Return multiple highlight segments
            return {
              { text = "[", highlight = "NeoTreeDimText" },
              { text = org, highlight = "@constant" },  -- Peach in catppuccin
              { text = "] ", highlight = "NeoTreeDimText" },
              { text = project, highlight = "NeoTreeDirectoryName" },
            }
          else
            -- Fallback to just the directory name
            if type(result) == 'table' then
              result.text = vim.fn.fnamemodify(node.path, ':t')
            end
          end
        end
        return result
      end
    '';

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
