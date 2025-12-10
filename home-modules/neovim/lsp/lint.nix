# nvim-lint configuration
# Asynchronous linting for Neovim
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.neovim-ide;

  # Linter packages from nixpkgs
  linters = {
    eslint_d = "${pkgs.eslint_d}/bin/eslint_d";
    ruff = "${pkgs.ruff}/bin/ruff";
    golangci-lint = "${pkgs.golangci-lint}/bin/golangci-lint";
    shellcheck = "${pkgs.shellcheck}/bin/shellcheck";
    markdownlint = "${pkgs.markdownlint-cli}/bin/markdownlint";
    yamllint = "${pkgs.yamllint}/bin/yamllint";
    statix = "${pkgs.statix}/bin/statix";
  };
in
{
  config = mkIf cfg.enable {
    # Add nvim-lint plugin
    programs.nvf.settings.vim.extraPlugins = {
      nvim-lint = {
        package = pkgs.vimPlugins.nvim-lint;
      };
    };

    # Configure nvim-lint
    programs.neovim-ide.luaConfigPost."45-nvim-lint" = ''
      -- nvim-lint configuration
      local lint = require('lint')

      -- Override linter commands with Nix store paths
      lint.linters.eslint_d.cmd = "${linters.eslint_d}"
      lint.linters.ruff.cmd = "${linters.ruff}"
      lint.linters.golangcilint.cmd = "${linters.golangci-lint}"
      lint.linters.shellcheck.cmd = "${linters.shellcheck}"
      lint.linters.markdownlint.cmd = "${linters.markdownlint}"
      lint.linters.yamllint.cmd = "${linters.yamllint}"
      lint.linters.statix.cmd = "${linters.statix}"

      -- Configure linters per filetype
      -- Note: JSON linting handled by LSP (jsonls)
      lint.linters_by_ft = {
        javascript = { 'eslint_d' },
        typescript = { 'eslint_d' },
        javascriptreact = { 'eslint_d' },
        typescriptreact = { 'eslint_d' },
        python = { 'ruff' },
        go = { 'golangcilint' },
        sh = { 'shellcheck' },
        bash = { 'shellcheck' },
        markdown = { 'markdownlint' },
        yaml = { 'yamllint' },
        nix = { 'statix' },
      }

      -- Auto-lint on events
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        callback = function()
          -- Only lint if the linter is available
          local ft = vim.bo.filetype
          local linters = lint.linters_by_ft[ft]
          if linters then
            lint.try_lint()
          end
        end,
      })

      -- Manual lint keymap
      vim.keymap.set("n", "<leader>cl", function()
        lint.try_lint()
      end, { desc = "Lint current file" })
    '';
  };
}
