# Format-on-save configuration
# Auto-format buffers on save using LSP
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
    programs.neovim-ide.luaConfigPost."50-format-on-save" = ''
      -- Format on save
      vim.g.format_on_save = true
      local format_group = vim.api.nvim_create_augroup("FormatOnSave", { clear = true })

      vim.api.nvim_create_autocmd("BufWritePre", {
        group = format_group,
        callback = function(args)
          if not vim.g.format_on_save then
            return
          end
          local clients = vim.lsp.get_clients({ bufnr = args.buf })
          for _, client in ipairs(clients) do
            if client.supports_method("textDocument/formatting") then
              vim.lsp.buf.format({
                bufnr = args.buf,
                async = false,
                timeout_ms = 3000,
              })
              return
            end
          end
        end,
      })

      -- Toggle format-on-save with <leader>uf
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
