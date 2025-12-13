-- WezTerm integration
-- Smart splits, image protocol, and terminal enhancements

local M = {}

function M.setup(opts)
  opts = opts or {}

  -- Undercurl support for WezTerm
  vim.cmd([[let &t_Cs = "\e[4:3m"]])
  vim.cmd([[let &t_Ce = "\e[4:0m"]])

  -- Smart splits setup
  require('smart-splits').setup({
    at_edge = 'stop',
    ignored_filetypes = { 'neo-tree' },
  })

  -- Navigation keymaps (Alt+Ctrl+Shift+hjkl sent by WezTerm)
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
