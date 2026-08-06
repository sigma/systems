# markdown-preview.nvim configuration
# Live preview for Markdown files in the browser
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
    programs.nvf.settings.vim.utility.preview.markdownPreview = {
      enable = true;
      # Don't auto-start, use keybinding instead
      autoStart = false;
      # Auto-close when leaving markdown buffer
      autoClose = true;
      # Only update on save for better performance
      lazyRefresh = true;
      # Only for markdown files
      filetypes = [ "markdown" ];
    };

    # Markdown preview keymaps (Lua module)
    programs.neovim-ide.luaConfigPost."60-markdown-preview-keymaps" = ''
      require('user.markdown').setup()
    '';
  };
}
