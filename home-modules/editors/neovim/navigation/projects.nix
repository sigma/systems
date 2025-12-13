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
    # Add project.nvim plugin
    programs.nvf.settings.vim.extraPlugins = {
      project-nvim = {
        package = pkgs.vimPlugins.project-nvim;
      };
    };

    # Setup project.nvim
    programs.neovim-ide.luaConfigPost."50-project-setup" = ''
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
    '';

    # Project management (Lua module)
    programs.neovim-ide.luaConfigPost."55-projects" = ''
      require('user.projects').setup()
    '';
  };
}
