-- LuaSnip snippet navigation keymaps
-- Tab/S-Tab for jumping, C-l for choice nodes

local M = {}

function M.setup(opts)
  opts = opts or {}

  local luasnip = require("luasnip")

  vim.keymap.set({ "i", "s" }, "<Tab>", function()
    if luasnip.expand_or_jumpable() then
      luasnip.expand_or_jump()
    else
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
    end
  end, { silent = true, desc = "Expand snippet or jump forward" })

  vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
    if luasnip.jumpable(-1) then
      luasnip.jump(-1)
    else
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<S-Tab>", true, false, true), "n", false)
    end
  end, { silent = true, desc = "Jump backward in snippet" })

  vim.keymap.set({ "i", "s" }, "<C-l>", function()
    if luasnip.choice_active() then
      luasnip.change_choice(1)
    end
  end, { silent = true, desc = "Select next snippet choice" })
end

return M
