# Core Neovim settings
# Options, globals, and basic behavior matching LazyVim defaults
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
    programs.nvf.settings.vim = {
      # Suppress lspconfig deprecation warning (nvf issue, not ours)
      luaConfigPre = ''
        local original_notify = vim.notify
        vim.notify = function(msg, level, opts)
          if type(msg) == "string" and msg:match("lspconfig.*deprecated") then
            return
          end
          return original_notify(msg, level, opts)
        end

        -- Also suppress vim.deprecate for this specific message
        local original_deprecate = vim.deprecate
        vim.deprecate = function(name, alternative, version, plugin, backtrace)
          if name and name:match("lspconfig") then
            return
          end
          return original_deprecate(name, alternative, version, plugin, backtrace)
        end

      '';

      # LSP and UI floating window borders
      luaConfigPost = ''
        -- Global border style for all floating windows
        local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
        function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
          opts = opts or {}
          opts.border = opts.border or "rounded"
          return orig_util_open_floating_preview(contents, syntax, opts, ...)
        end

        -- Diagnostic floating windows
        vim.diagnostic.config({
          float = {
            border = "rounded",
            source = true,
          },
        })

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

      # Global variables
      globals = {
        # Leader keys
        mapleader = " ";
        maplocalleader = "\\";
      };

      # Neovim options (vim.o.*)
      options = {
        # Line numbers
        number = true;
        relativenumber = true;

        # Sign column (for git signs, diagnostics, etc.)
        signcolumn = "yes";

        # Cursor
        cursorline = true;

        # Colors
        termguicolors = true;

        # Clipboard - use system clipboard
        clipboard = "unnamedplus";

        # Mouse support
        mouse = "a";

        # Persistent undo
        undofile = true;

        # Search
        ignorecase = true;
        smartcase = true;
        hlsearch = true;
        incsearch = true;

        # Splits
        splitbelow = true;
        splitright = true;

        # Scrolling
        scrolloff = 8;
        sidescrolloff = 8;

        # Indentation
        tabstop = 2;
        shiftwidth = 2;
        softtabstop = 2;
        expandtab = true;
        smartindent = true;

        # Line wrapping
        wrap = false;

        # Completion
        completeopt = "menu,menuone,noselect";

        # Update time (for CursorHold events)
        updatetime = 250;

        # Timeout for key sequences
        timeoutlen = 300;

        # Show matching brackets
        showmatch = true;

        # Don't show mode (shown in statusline)
        showmode = false;

        # Don't show partial commands in bottom right
        showcmd = false;

        # Command line height
        cmdheight = 1;

        # Pop-up menu height
        pumheight = 10;

        # Conceal level for markdown etc.
        conceallevel = 2;

        # File encoding
        fileencoding = "utf-8";

        # Backup/swap files (disabled, rely on undofile)
        backup = false;
        swapfile = false;
        writebackup = false;

        # Split window sizing
        equalalways = false;

        # Allow hidden buffers
        hidden = true;

        # Spelling
        spell = false;
        spelllang = "en_us";
      };
    };
  };
}
