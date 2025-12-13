-- WezTerm integration
-- Smart splits, image protocol, inactive window dimming, and terminal enhancements

local M = {}

function M.setup(opts)
  opts = opts or {}

  -- Undercurl support for WezTerm
  vim.cmd([[let &t_Cs = "\e[4:3m"]])
  vim.cmd([[let &t_Ce = "\e[4:0m"]])

  -- Dim inactive windows to match WezTerm's inactive_pane_hsb
  -- WezTerm uses: saturation = 0.9, brightness = 0.65
  -- Since we use transparent backgrounds, we need to set an actual bg color
  -- on inactive windows to simulate the dimming effect.
  -- When Neovim loses focus entirely, we remove the dim so WezTerm's
  -- pane dimming doesn't stack on top of ours.
  local function setup_inactive_window_dimming()
    local dim_bg = '#161621'
    local augroup = vim.api.nvim_create_augroup('InactiveWindowDim', { clear = true })

    local function apply_dim()
      vim.api.nvim_set_hl(0, 'NormalNC', { bg = dim_bg })
      vim.api.nvim_set_hl(0, 'NeoTreeNormalNC', { bg = dim_bg })
      vim.api.nvim_set_hl(0, 'EndOfBufferNC', { bg = dim_bg, fg = dim_bg })
    end

    local function clear_dim()
      vim.api.nvim_set_hl(0, 'NormalNC', {})
      vim.api.nvim_set_hl(0, 'NeoTreeNormalNC', {})
      vim.api.nvim_set_hl(0, 'EndOfBufferNC', {})
    end

    -- Apply dimming initially (assume focused)
    apply_dim()

    -- Toggle dimming based on Neovim focus
    vim.api.nvim_create_autocmd('FocusGained', {
      group = augroup,
      callback = apply_dim,
    })

    vim.api.nvim_create_autocmd('FocusLost', {
      group = augroup,
      callback = clear_dim,
    })

    -- Re-apply after colorscheme changes (only if focused)
    vim.api.nvim_create_autocmd('ColorScheme', {
      group = augroup,
      callback = function()
        -- Check if we're focused by looking at current highlight
        local nc = vim.api.nvim_get_hl(0, { name = 'NormalNC' })
        if nc.bg then
          apply_dim()
        end
      end,
    })
  end

  setup_inactive_window_dimming()

  -- Smart splits setup
  require('smart-splits').setup({
    at_edge = 'stop',
    ignored_filetypes = { 'neo-tree' },
  })

  -- Navigation keymaps (Alt+Ctrl+Shift+hjkl sent by WezTerm via CSI u encoding)
  vim.keymap.set('n', '<M-C-S-h>', require('smart-splits').move_cursor_left, { desc = 'Move to left split/pane' })
  vim.keymap.set('n', '<M-C-S-l>', require('smart-splits').move_cursor_right, { desc = 'Move to right split/pane' })
  vim.keymap.set('n', '<M-C-S-k>', require('smart-splits').move_cursor_up, { desc = 'Move to upper split/pane' })
  vim.keymap.set('n', '<M-C-S-j>', require('smart-splits').move_cursor_down, { desc = 'Move to lower split/pane' })

  -- Resize keymaps
  vim.keymap.set('n', '<M-C-S-Left>', require('smart-splits').resize_left, { desc = 'Resize split left' })
  vim.keymap.set('n', '<M-C-S-Right>', require('smart-splits').resize_right, { desc = 'Resize split right' })
  vim.keymap.set('n', '<M-C-S-Up>', require('smart-splits').resize_up, { desc = 'Resize split up' })
  vim.keymap.set('n', '<M-C-S-Down>', require('smart-splits').resize_down, { desc = 'Resize split down' })

  -- Swap buffer keymaps
  vim.keymap.set('n', '<leader>wh', require('smart-splits').swap_buf_left, { desc = 'Swap buffer left' })
  vim.keymap.set('n', '<leader>wj', require('smart-splits').swap_buf_down, { desc = 'Swap buffer down' })
  vim.keymap.set('n', '<leader>wk', require('smart-splits').swap_buf_up, { desc = 'Swap buffer up' })
  vim.keymap.set('n', '<leader>wl', require('smart-splits').swap_buf_right, { desc = 'Swap buffer right' })

  -- Image.nvim setup for WezTerm image protocol
  require('image').setup({
    backend = 'kitty',
    integrations = {
      markdown = {
        enabled = true,
        clear_in_insert_mode = false,
        download_remote_images = true,
        only_render_image_at_cursor = false,
        filetypes = { 'markdown', 'vimwiki' },
      },
      neorg = {
        enabled = false,
      },
    },
    max_width = nil,
    max_height = nil,
    max_width_window_percentage = nil,
    max_height_window_percentage = 50,
    window_overlap_clear_enabled = false,
    window_overlap_clear_ft_ignore = { 'cmp_menu', 'cmp_docs', '' },
    editor_only_render_when_focused = false,
    tmux_show_only_in_active_window = false,
    hijack_file_patterns = { '*.png', '*.jpg', '*.jpeg', '*.gif', '*.webp' },
  })
end

return M
