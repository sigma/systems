# project.nvim configuration
# Project management with Telescope integration
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
    # project.nvim - lazy load after UI is ready
    programs.nvf.settings.vim.lazy.plugins = {
      "project.nvim" = {
        package = pkgs.vimPlugins.project-nvim;
        event = [ "UIEnter" ];
        after = ''
          require('project').setup({
            use_lsp = true,
            patterns = {
              ".git", "_darcs", ".hg", ".bzr", ".svn",
              "Makefile", "package.json", "flake.nix",
              "Cargo.toml", "go.mod", "pyproject.toml", "setup.py",
            },
            manual_mode = false,
            silent_chdir = false,
            scope_chdir = "tab",
          })
          require('telescope').load_extension('projects')
          require('user.projects').setup()
        '';
      };
    };
  };
}
