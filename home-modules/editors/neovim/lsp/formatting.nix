# conform.nvim configuration
# Format-on-save with per-filetype formatter control
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.neovim-ide;
in
{
  config = mkIf cfg.enable {
    programs.nvf.settings.vim.formatter.conform-nvim = {
      enable = true;

      setupOpts = {
        format_on_save = {
          __raw = ''
            function(bufnr)
              if not vim.g.format_on_save then
                return
              end
              if vim.b[bufnr].disable_format_save then
                return
              end
              return { timeout_ms = 3000, lsp_format = "fallback" }
            end
          '';
        };
      };
    };

    # Initialize format_on_save toggle
    programs.neovim-ide.luaConfigPost."50-format-on-save" = ''
      vim.g.format_on_save = true

      vim.keymap.set("n", "<leader>uf", function()
        vim.g.format_on_save = not vim.g.format_on_save
        if vim.g.format_on_save then
          vim.notify("Format on save enabled", vim.log.levels.INFO)
        else
          vim.notify("Format on save disabled", vim.log.levels.INFO)
        end
      end, { desc = "Toggle format on save" })
    '';
  };
}
