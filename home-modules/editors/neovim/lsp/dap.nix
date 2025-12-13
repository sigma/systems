# nvim-dap debugging configuration
# Debug Adapter Protocol support with UI
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.neovim-ide;
  icons = import ../icons.nix;
in
{
  config = mkIf cfg.enable {
    programs.nvf.settings.vim.debugger.nvim-dap = {
      enable = true;

      # Enable the DAP UI
      ui = {
        enable = true;
        autoStart = true;
      };

      # LazyVim-style keymaps (under <leader>d prefix)
      mappings = {
        continue = "<leader>dc";
        restart = "<leader>dR";
        terminate = "<leader>dq";
        runLast = "<leader>d.";
        toggleRepl = "<leader>dr";
        hover = "<leader>dh";
        toggleBreakpoint = "<leader>db";
        runToCursor = "<leader>dC";
        stepInto = "<leader>di";
        stepOut = "<leader>do";
        stepOver = "<leader>dn";
        stepBack = "<leader>dk";
        goUp = "<leader>dU";
        goDown = "<leader>dD";
        toggleDapUI = "<leader>du";
      };
    };

    # Configure DAP signs (Lua module)
    programs.neovim-ide.luaConfigPost."50-dap-signs" = ''
      require('user.dap').setup({
        icons = {
          breakpoint = "${icons.dap.breakpoint}",
          breakpointCondition = "${icons.dap.breakpointCondition}",
          breakpointRejected = "${icons.dap.breakpointRejected}",
          logPoint = "${icons.dap.logPoint}",
          stopped = "${icons.dap.Stopped}",
        },
      })
    '';

    # Enable DAP for languages
    programs.nvf.settings.vim.languages = {
      # Go debugging with delve
      go.dap = {
        enable = true;
        debugger = "delve";
      };

      # Python debugging
      python.dap = {
        enable = true;
      };

      # Rust debugging
      rust.dap.enable = true;
    };
  };
}
