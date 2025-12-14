# WezTerm integration
# Smart splits, image protocol, and terminal enhancements
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
    # WezTerm integration plugins - lazy loaded
    programs.nvf.settings.vim.lazy.plugins = {
      "smart-splits.nvim" = {
        package = pkgs.vimPlugins.smart-splits-nvim;
        event = [ "UIEnter" ];
        after = ''
          require('user.wezterm').setup()
        '';
      };
      "image.nvim" = {
        package = pkgs.vimPlugins.image-nvim;
        ft = [ "markdown" "neorg" "html" ];
        after = ''
          require('image').setup({
            backend = "kitty",
            integrations = {
              markdown = { enabled = true },
              neorg = { enabled = true },
            },
          })
        '';
      };
    };
  };
}
