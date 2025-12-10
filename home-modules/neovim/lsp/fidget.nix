# Fidget.nvim configuration
# LSP progress indicator in the corner
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
    programs.nvf.settings.vim.extraPlugins = {
      fidget-nvim = {
        package = pkgs.vimPlugins.fidget-nvim;
        setup = ''
          require('fidget').setup({
            -- Notification options
            notification = {
              -- How long notifications stay visible
              poll_rate = 10,
              filter = vim.log.levels.INFO,
              override_vim_notify = false,
              window = {
                winblend = 0,
                border = "none",
              },
            },
            -- Progress display options
            progress = {
              poll_rate = 0,
              suppress_on_insert = true,
              ignore_done_already = true,
              ignore_empty_message = false,
              display = {
                render_limit = 16,
                done_ttl = 3,
                progress_style = "WarningMsg",
                icon_style = "Question",
                done_icon = "✓",
                done_style = "Constant",
              },
            },
          })
        '';
      };
    };
  };
}
