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
    # nvim-lint - lazy load on file read/write
    programs.nvf.settings.vim.lazy.plugins = {
      "nvim-lint" = {
        package = pkgs.vimPlugins.nvim-lint;
        event = [ "BufReadPost" "BufWritePost" ];
        after = ''
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
    };
  };
}
