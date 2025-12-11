# noice.nvim configuration
# Replaces the UI for messages, cmdline and popupmenu
# Similar to LazyVim's noice configuration
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
    programs.nvf.settings.vim.ui.noice = {
      enable = true;
      setupOpts = {
        # LSP overrides for better rendering
        lsp = {
          override = {
            "vim.lsp.util.convert_input_to_markdown_lines" = true;
            "vim.lsp.util.stylize_markdown" = true;
            "cmp.entry.get_documentation" = true;
          };
          # Disable signature since we use lsp_signature or fidget
          signature.enabled = false;
        };

        # Presets matching LazyVim defaults
        presets = {
          # Use classic bottom cmdline for search
          bottom_search = true;
          # Position cmdline and popupmenu together
          command_palette = true;
          # Send long messages to a split
          long_message_to_split = true;
          # Enable inc-rename input dialog
          inc_rename = false;
          # Add border to LSP hover docs
          lsp_doc_border = true;
        };
      };
    };
  };
}
