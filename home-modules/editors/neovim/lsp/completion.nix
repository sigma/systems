# Completion configuration
# blink.cmp - fast Rust-based completion engine
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
    programs.nvf.settings.vim.autocomplete.blink-cmp = {
      enable = true;

      # Enable friendly-snippets integration
      friendly-snippets.enable = true;

      setupOpts = {
        # Completion sources
        sources.default = [
          "lsp"
          "path"
          "snippets"
          "buffer"
        ];

        # Documentation popup
        completion.documentation = {
          auto_show = true;
          auto_show_delay_ms = 200;
        };

        # Fuzzy matching - prefer Rust for performance, fall back to Lua
        fuzzy.implementation = "prefer_rust";
      };

      # Key mappings matching LazyVim
      mappings = {
        complete = "<C-Space>";
        confirm = "<CR>";
        next = "<Tab>";
        previous = "<S-Tab>";
        close = "<C-e>";
        scrollDocsUp = "<C-b>";
        scrollDocsDown = "<C-f>";
      };
    };
  };
}
