# Comments configuration
# Toggle comments with gc
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
    programs.nvf.settings.vim.comments.comment-nvim = {
      enable = true;
    };
  };
}
