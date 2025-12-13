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

    # Configure DAP signs with icons
    programs.neovim-ide.luaConfigPost."50-dap-signs" = ''
      -- DAP breakpoint signs
      vim.fn.sign_define("DapBreakpoint", { text = "${icons.dap.breakpoint}", texthl = "DapBreakpoint" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "${icons.dap.breakpointCondition}", texthl = "DapBreakpointCondition" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "${icons.dap.breakpointRejected}", texthl = "DapBreakpointRejected" })
      vim.fn.sign_define("DapLogPoint", { text = "${icons.dap.logPoint}", texthl = "DapLogPoint" })
      vim.fn.sign_define("DapStopped", { text = "${icons.dap.Stopped}", texthl = "DapStopped", linehl = "DapStoppedLine" })
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
