# LuaSnip and snippets configuration
# Snippet engine with friendly-snippets collection
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
    programs.nvf.settings.vim.snippets.luasnip = {
      enable = true;

      # Load friendly-snippets (VS Code compatible snippets)
      providers = [ "friendly-snippets" ];

      # Enable auto-snippets
      setupOpts = {
        enable_autosnippets = true;
        history = true;
      };
    };

    # Snippet placeholder navigation keymaps (Lua module)
    programs.neovim-ide.luaConfigPost."40-snippet-keymaps" = ''
      require('user.snippets').setup()
    '';
  };
}
