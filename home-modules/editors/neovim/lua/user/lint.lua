-- nvim-lint configuration
-- Asynchronous linting for Neovim

local M = {}

function M.setup(opts)
  opts = opts or {}
  local linters = opts.linters or {}

  local lint = require('lint')

  -- Override linter commands with Nix store paths
  if linters.eslint_d then lint.linters.eslint_d.cmd = linters.eslint_d end
  if linters.ruff then lint.linters.ruff.cmd = linters.ruff end
  if linters.golangci_lint then lint.linters.golangcilint.cmd = linters.golangci_lint end
  if linters.shellcheck then lint.linters.shellcheck.cmd = linters.shellcheck end
  if linters.markdownlint then lint.linters.markdownlint.cmd = linters.markdownlint end
  if linters.yamllint then lint.linters.yamllint.cmd = linters.yamllint end
  if linters.statix then lint.linters.statix.cmd = linters.statix end

  -- Configure linters per filetype
  lint.linters_by_ft = {
    javascript = { 'eslint_d' },
    typescript = { 'eslint_d' },
    javascriptreact = { 'eslint_d' },
    typescriptreact = { 'eslint_d' },
    python = { 'ruff' },
    go = { 'golangcilint' },
    sh = { 'shellcheck' },
    bash = { 'shellcheck' },
    markdown = { 'markdownlint' },
    yaml = { 'yamllint' },
    nix = { 'statix' },
  }

  -- Auto-lint on events
  vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
    callback = function()
      local ft = vim.bo.filetype
      local ft_linters = lint.linters_by_ft[ft]
      if ft_linters then
        lint.try_lint()
      end
    end,
  })

  -- Manual lint keymap
  vim.keymap.set("n", "<leader>cl", function()
    lint.try_lint()
  end, { desc = "Lint current file" })
end

return M
