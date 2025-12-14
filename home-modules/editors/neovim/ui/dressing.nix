# dressing.nvim configuration
# Better UI for vim.ui.select and vim.ui.input
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
    # dressing.nvim - lazy load after UI is ready
    programs.nvf.settings.vim.lazy.plugins = {
      "dressing.nvim" = {
        package = pkgs.vimPlugins.dressing-nvim;
        event = [ "UIEnter" ];
        after = ''
          require('dressing').setup({
            input = {
              enabled = true,
              default_prompt = "Input:",
              title_pos = "center",
              insert_only = true,
              start_in_insert = true,
              border = "rounded",
              relative = "cursor",
              prefer_width = 40,
              max_width = { 140, 0.9 },
              min_width = { 20, 0.2 },
              win_options = { winblend = 0, wrap = false },
            },
            select = {
              enabled = true,
              backend = { "telescope", "builtin" },
              trim_prompt = true,
              builtin = {
                border = "rounded",
                relative = "editor",
                win_options = { winblend = 0 },
                max_width = { 140, 0.8 },
                min_width = { 40, 0.2 },
                max_height = 0.9,
                min_height = { 10, 0.2 },
              },
            },
          })
        '';
      };
    };
  };
}
