# Lualine statusline configuration
# LazyVim-style with rounded bubble separators
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.neovim-ide;
  icons = import ../icons.nix;
in
{
  config = mkIf cfg.enable {
    programs.nvf.settings.vim.statusline.lualine = {
      enable = true;

      # Use catppuccin theme (auto will pick up from vim.theme)
      theme = "auto";

      # Section separators for bubble effect, no component separators
      sectionSeparator = {
        left = icons.separators.right;
        right = icons.separators.left;
      };
      componentSeparator = {
        left = "";
        right = "";
      };

      # Global statusline
      globalStatus = true;

      # Custom sections matching LazyVim + user preferences
      activeSection = {
        # Mode with left bubble cap
        a = [
          ''{ "mode", separator = { left = "${icons.separators.left}" }, right_padding = 2 }''
        ];
        # Git branch and diff (LazyVim defaults)
        b = [
          ''"branch"''
          ''{ "diff", symbols = { added = "${icons.git.added}", modified = "${icons.git.modified}", removed = "${icons.git.removed}" } }''
        ];
        # Filename and diagnostics
        c = [
          ''{ "filename", path = 1 }''
          ''{ "diagnostics", symbols = { error = "${icons.diagnostics.error}", warn = "${icons.diagnostics.warn}", info = "${icons.diagnostics.info}", hint = "${icons.diagnostics.hint}" } }''
        ];
        # Tab/workspace indicator (only shown when multiple tabs exist)
        x = [
          ''
            {
              function()
                local tab_nr = vim.fn.tabpagenr()
                local tab_name = vim.fn.gettabvar(tab_nr, 'tab_name', "")
                if tab_name == "" then
                  tab_name = tostring(tab_nr)
                end
                return "${icons.ui.tabs}" .. tab_name
              end,
              cond = function() return vim.fn.tabpagenr('$') > 1 end,
            }
          ''
        ];
        # Progress and location
        y = [
          ''{ "progress", separator = " ", padding = { left = 1, right = 0 } }''
          ''{ "location", padding = { left = 0, right = 1 } }''
        ];
        # Clock with right bubble cap
        z = [
          ''{ function() return "${icons.ui.clock}" .. os.date("%R") end, separator = { right = "${icons.separators.right}" } }''
        ];
      };
    };

    # Tab management (Lua module)
    programs.neovim-ide.luaConfigPost."60-tabs" = ''
      require('user.tabs').setup()
    '';
  };
}
