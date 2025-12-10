# Completion configuration
# nvim-cmp with LSP, buffer, path sources
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
    programs.nvf.settings.vim.autocomplete.nvim-cmp = {
      enable = true;

      # Completion behavior
      setupOpts = {
        completion = {
          completeopt = "menu,menuone,noinsert";
        };

        # Window styling - add borders for visibility with transparent background
        window = {
          completion = {
            border = "rounded";
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None";
          };
          documentation = {
            border = "rounded";
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder";
          };
        };
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
