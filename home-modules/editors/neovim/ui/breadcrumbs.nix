# nvim-navic breadcrumbs configuration
# Shows code context (function/class/etc) in the winbar
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
    programs.nvf.settings.vim.ui.breadcrumbs = {
      enable = true;
      # Use nvim-navic as the source
      source = "nvim-navic";
      # Disable nvf's default winbar, we'll configure it manually
      lualine.winbar.enable = false;
    };

    # Configure winbar for both active and inactive windows
    programs.neovim-ide.luaConfigPost."15-winbar" = ''
      -- Custom winbar showing breadcrumbs on all windows
      local navic = require('nvim-navic')

      local function get_winbar()
        if navic.is_available() then
          local location = navic.get_location()
          if location ~= "" then
            return "%#WinBar# " .. location
          end
        end
        return ""
      end

      -- Winbar for inactive windows (dimmed)
      local function get_inactive_winbar()
        if navic.is_available() then
          local location = navic.get_location()
          if location ~= "" then
            return "%#WinBarNC# " .. location
          end
        end
        return ""
      end

      -- Set up winbar via lualine
      require('lualine').setup({
        options = {
          disabled_filetypes = {
            winbar = { 'neo-tree', 'dashboard', 'alpha', 'starter', 'toggleterm', 'TelescopePrompt' },
          },
        },
        winbar = {
          lualine_c = {
            {
              function() return get_winbar() end,
              color = { bg = 'NONE' },
            },
          },
        },
        inactive_winbar = {
          lualine_c = {
            {
              function() return get_inactive_winbar() end,
              color = { bg = 'NONE' },
            },
          },
        },
      })
    '';
  };
}
