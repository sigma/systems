# inc-rename.nvim configuration
# Live preview of LSP renames in the buffer
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
    # inc-rename.nvim - lazy load on command
    programs.nvf.settings.vim.lazy.plugins = {
      "inc-rename.nvim" = {
        package = pkgs.vimPlugins.inc-rename-nvim;
        cmd = [ "IncRename" ];
        after = ''
          require('inc_rename').setup()
        '';
      };
    };

    # Keymap needs expr=true with a Lua function, which nvf keymaps
    # don't support (action must be a string). Set it up via luaConfigPost.
    programs.neovim-ide.luaConfigPost."50-inc-rename-keymap" = ''
      vim.keymap.set("n", "<leader>cr", function()
        return ":IncRename " .. vim.fn.expand("<cword>")
      end, { expr = true, desc = "Rename (inc-rename)" })
    '';

    # Enable noice inc-rename preset
    programs.nvf.settings.vim.ui.noice.setupOpts.presets.inc_rename = true;
  };
}
