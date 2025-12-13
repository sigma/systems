-- Tab management with Telescope integration
-- Provides tab commands, keymaps, and picker

local M = {}

-- Telescope tab picker
local function tab_picker()
  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')

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

  pickers.new({
    selection_caret = "> ",
  }, {
    prompt_title = 'Tabs',
    finder = finders.new_table({
      results = tabs,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.display,
          ordinal = entry.display,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
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
end

-- Setup function called from Nix
function M.setup(opts)
  opts = opts or {}

  -- Tab naming command
  vim.api.nvim_create_user_command('TabRename', function(cmd_opts)
    vim.fn.settabvar(vim.fn.tabpagenr(), 'tab_name', cmd_opts.args)
  end, { nargs = 1, desc = 'Rename current tab' })

  -- Tab keymaps
  vim.keymap.set('n', '<leader><tab>n', '<cmd>tabnew<cr>', { desc = 'New tab' })
  vim.keymap.set('n', '<leader><tab>c', '<cmd>tabclose<cr>', { desc = 'Close tab' })
  vim.keymap.set('n', '<leader><tab>]', '<cmd>tabnext<cr>', { desc = 'Next tab' })
  vim.keymap.set('n', '<leader><tab>[', '<cmd>tabprevious<cr>', { desc = 'Previous tab' })
  vim.keymap.set('n', '<leader><tab>l', '<cmd>tablast<cr>', { desc = 'Last tab' })
  vim.keymap.set('n', '<leader><tab>f', '<cmd>tabfirst<cr>', { desc = 'First tab' })
  vim.keymap.set('n', '<leader><tab>r', ':TabRename ', { desc = 'Rename tab' })

  -- Number-based tab switching
  for i = 1, 9 do
    vim.keymap.set('n', '<leader><tab>' .. i, i .. 'gt', { desc = 'Go to tab ' .. i })
  end

  -- Telescope tab picker
  vim.keymap.set('n', '<leader>ft', tab_picker, { desc = 'Find tabs' })
end

return M
