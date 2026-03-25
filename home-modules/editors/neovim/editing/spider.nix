# nvim-spider configuration
# Override w/b/e motions to respect camelCase and snake_case boundaries
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
      "nvim-spider" = {
        package = pkgs.vimPlugins.nvim-spider;
        event = [ "BufReadPost" "BufNewFile" ];
        after = ''
          require('spider').setup({
            skipInsignificantPunctuation = true,
          })

          vim.keymap.set({"n", "o", "x"}, "w", "<cmd>lua require('spider').motion('w')<CR>", { desc = "Spider w" })
          vim.keymap.set({"n", "o", "x"}, "e", "<cmd>lua require('spider').motion('e')<CR>", { desc = "Spider e" })
          vim.keymap.set({"n", "o", "x"}, "b", "<cmd>lua require('spider').motion('b')<CR>", { desc = "Spider b" })
        '';
      };
    };
  };
}
