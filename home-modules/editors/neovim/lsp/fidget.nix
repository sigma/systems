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
    # fidget.nvim - lazy load on LSP attach
    programs.nvf.settings.vim.lazy.plugins = {
      "fidget.nvim" = {
        package = pkgs.vimPlugins.fidget-nvim;
        event = [ "LspAttach" ];
        after = ''
          require('fidget').setup({
            notification = {
              poll_rate = 10,
              filter = vim.log.levels.INFO,
              override_vim_notify = false,
              window = { winblend = 0, border = "none" },
            },
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
