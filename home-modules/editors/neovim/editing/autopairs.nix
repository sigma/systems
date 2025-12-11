# Autopairs configuration
# Auto-close brackets, quotes, etc.
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
    programs.nvf.settings.vim.autopairs.nvim-autopairs = {
      enable = true;
    };
  };
}
