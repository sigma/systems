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

    # Tab management keymaps and commands
    programs.neovim-ide.luaConfigPost."60-tabs" = ''
      -- Tab naming: store name in tab-local variable
      vim.api.nvim_create_user_command('TabRename', function(opts)
        vim.fn.settabvar(vim.fn.tabpagenr(), 'tab_name', opts.args)
      end, { nargs = 1, desc = 'Rename current tab' })

      -- Tab keymaps
      vim.keymap.set('n', '<leader><tab>n', '<cmd>tabnew<cr>', { desc = 'New tab' })
      vim.keymap.set('n', '<leader><tab>c', '<cmd>tabclose<cr>', { desc = 'Close tab' })
      vim.keymap.set('n', '<leader><tab>]', '<cmd>tabnext<cr>', { desc = 'Next tab' })
      vim.keymap.set('n', '<leader><tab>[', '<cmd>tabprevious<cr>', { desc = 'Previous tab' })
      vim.keymap.set('n', '<leader><tab>l', '<cmd>tablast<cr>', { desc = 'Last tab' })
      vim.keymap.set('n', '<leader><tab>f', '<cmd>tabfirst<cr>', { desc = 'First tab' })
      vim.keymap.set('n', '<leader><tab>r', ':TabRename ', { desc = 'Rename tab' })

      -- Quick tab switching with gt/gT (native vim)
      -- Also add number-based switching
      for i = 1, 9 do
        vim.keymap.set('n', '<leader><tab>' .. i, i .. 'gt', { desc = 'Go to tab ' .. i })
      end

      -- Telescope tab picker
      vim.keymap.set('n', '<leader>ft', function()
        local tabs = {}
        for i = 1, vim.fn.tabpagenr('$') do
          local tab_name = vim.fn.gettabvar(i, 'tab_name', "")
          local buflist = vim.fn.tabpagebuflist(i)
          local winnr = vim.fn.tabpagewinnr(i)
          local bufnr = buflist[winnr]
          local bufname = vim.fn.bufname(bufnr)
          local display = tab_name ~= "" and tab_name or (bufname ~= "" and vim.fn.fnamemodify(bufname, ':t') or "[No Name]")
          table.insert(tabs, {
            tab_nr = i,
            display = string.format("%d: %s", i, display),
            name = tab_name,
            bufname = bufname,
          })
        end

        require('telescope.pickers').new({
          selection_caret = "> ",
        }, {
          prompt_title = 'Tabs',
          finder = require('telescope.finders').new_table({
            results = tabs,
            entry_maker = function(entry)
              return {
                value = entry,
                display = entry.display,
                ordinal = entry.display,
              }
            end,
          }),
          sorter = require('telescope.config').values.generic_sorter({}),
          attach_mappings = function(prompt_bufnr, map)
            local actions = require('telescope.actions')
            local action_state = require('telescope.actions.state')
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local selection = action_state.get_selected_entry()
              if selection then
                vim.cmd('tabnext ' .. selection.value.tab_nr)
              end
            end)
            return true
          end,
        }):find()
      end, { desc = 'Find tabs' })
    '';
  };
}
