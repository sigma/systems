# oil.nvim configuration
# Edit your filesystem like a buffer
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
    programs.nvf.settings.vim.utility.oil-nvim = {
      enable = true;

      # Enable git status indicators in directory listings
      gitStatus = {
        enable = true;
      };

      setupOpts = {
        # Use floating window for oil
        float = {
          padding = 2;
          max_width = 100;
          max_height = 30;
        };
        # Show hidden files
        view_options = {
          show_hidden = true;
        };
      };
    };

    # Keymaps
    programs.nvf.settings.vim.keymaps = [
      {
        key = "-";
        mode = [ "n" ];
        action = "<cmd>Oil<cr>";
        desc = "Open parent directory";
      }
      {
        key = "<leader>o";
        mode = [ "n" ];
        action = "<cmd>Oil --float<cr>";
        desc = "Open Oil (floating)";
      }
    ];
  };
}
