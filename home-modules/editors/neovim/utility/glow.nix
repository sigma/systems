# glow.nvim configuration
# Terminal-based markdown preview using glow
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
    programs.nvf.settings.vim.utility.preview.glow = {
      enable = true;
      # Use <leader>mg for glow (g for glow, vs mp for browser preview)
      mappings.openPreview = "<leader>mg";
    };
  };
}
