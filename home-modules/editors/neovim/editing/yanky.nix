# yanky.nvim configuration
# Improved yank/paste with yank ring - cycle through previous yanks
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
    programs.nvf.settings.vim.lazy.plugins = {
      "yanky.nvim" = {
        package = pkgs.vimPlugins.yanky-nvim;
        event = [ "BufReadPost" "BufNewFile" ];
        after = ''
          require('yanky').setup({
            ring = {
              history_length = 100,
              storage = "shada",
            },
            highlight = {
              on_put = true,
              on_yank = true,
              timer = 200,
            },
          })

          -- Remap p/P to use yanky
          vim.keymap.set({"n","x"}, "p", "<Plug>(YankyPutAfter)")
          vim.keymap.set({"n","x"}, "P", "<Plug>(YankyPutBefore)")
          vim.keymap.set({"n","x"}, "gp", "<Plug>(YankyGPutAfter)")
          vim.keymap.set({"n","x"}, "gP", "<Plug>(YankyGPutBefore)")

          -- Cycle through yank ring after pasting
          vim.keymap.set("n", "<C-p>", "<Plug>(YankyPreviousEntry)")
          vim.keymap.set("n", "<C-n>", "<Plug>(YankyNextEntry)")
        '';
      };
    };
  };
}
