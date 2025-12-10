# Gitsigns configuration
# Git signs in signcolumn, hunk navigation
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
    # Enable git support
    programs.nvf.settings.vim.git.enable = true;

    programs.nvf.settings.vim.git.gitsigns = {
      enable = true;

      # LazyVim-style keymaps
      mappings = {
        # Hunk navigation
        nextHunk = "]h";
        previousHunk = "[h";
        # Staging
        stageHunk = "<leader>ghs";
        stageBuffer = "<leader>ghS";
        undoStageHunk = "<leader>ghu";
        # Reset
        resetHunk = "<leader>ghr";
        resetBuffer = "<leader>ghR";
        # Preview/blame
        previewHunk = "<leader>ghp";
        blameLine = "<leader>ghb";
        toggleBlame = "<leader>gtb";
        # Diff
        diffThis = "<leader>ghd";
        diffProject = "<leader>ghD";
      };
    };
  };
}
