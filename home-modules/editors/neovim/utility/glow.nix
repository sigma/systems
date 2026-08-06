# glow.nvim configuration
# Terminal-based markdown preview using glow
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
    programs.nvf.settings.vim.utility.preview.glow = {
      enable = true;
      # Use <leader>mg for glow (g for glow, vs mp for browser preview)
      mappings.openPreview = "<leader>mg";
    };

    # Configure glow (Lua module)
    programs.neovim-ide.luaConfigPost."20-glow-setup" = ''
      require('user.glow').setup({
        glow_path = "${pkgs.glow}/bin/glow",
      })
    '';
  };
}
