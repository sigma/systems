# lazygit.nvim integration
# Toggle lazygit in a floating terminal window
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
    # lazygit.nvim - lazy load on command
    programs.nvf.settings.vim.lazy.plugins = {
      "lazygit.nvim" = {
        package = pkgs.vimPlugins.lazygit-nvim;
        cmd = [ "LazyGit" "LazyGitConfig" "LazyGitCurrentFile" "LazyGitFilter" "LazyGitFilterCurrentFile" ];
        after = ''
          require('user.lazygit').setup()
        '';
      };
    };
  };
}
