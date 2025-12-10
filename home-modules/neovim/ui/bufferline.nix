# Bufferline configuration
# Buffer tabs at top with close buttons and indicators
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
    programs.nvf.settings.vim.tabline.nvimBufferline = {
      enable = true;

      # Show buffers (not tabs)
      setupOpts = {
        options = {
          mode = "buffers";

          # Slant style separators for visual distinction
          separator_style = "slant";

          # Show diagnostics from LSP
          diagnostics = "nvim_lsp";

          # Show close button
          show_close_icon = true;
          show_buffer_close_icons = true;

          # Show modified indicator
          modified_icon = "●";

          # Offset for neo-tree
          offsets = [
            {
              filetype = "neo-tree";
              text = "File Explorer";
              highlight = "Directory";
              separator = true;
            }
          ];

          # Visual settings
          color_icons = true;
          show_buffer_icons = true;
          show_tab_indicators = true;

          # Only show bufferline when there are multiple buffers
          always_show_bufferline = false;
        };
      };

      # Key mappings
      mappings = {
        cycleNext = "<S-l>";
        cyclePrevious = "<S-h>";
        pick = "<leader>bp";
        closeCurrent = "<leader>bd";
        sortByDirectory = "<leader>bsd";
        sortByExtension = "<leader>bse";
      };
    };
  };
}
