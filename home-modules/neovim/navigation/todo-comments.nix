# Todo-comments configuration
# Highlight and search TODO, FIXME, HACK, etc.
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
    programs.nvf.settings.vim.notes.todo-comments = {
      enable = true;

      # Keymaps
      mappings = {
        quickFix = "<leader>xT";
        telescope = "<leader>st";
        trouble = "<leader>xt";
      };
    };
  };
}
