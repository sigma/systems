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

    # Configure nvim-lint (Lua module)
    programs.neovim-ide.luaConfigPost."45-nvim-lint" = ''
      require('user.lint').setup({
        linters = {
          eslint_d = "${linters.eslint_d}",
          ruff = "${linters.ruff}",
          golangci_lint = "${linters.golangci-lint}",
          shellcheck = "${linters.shellcheck}",
          markdownlint = "${linters.markdownlint}",
          yamllint = "${linters.yamllint}",
          statix = "${linters.statix}",
        },
      })
    '';
  };
}
