# Core Neovim settings
# Options, globals, and basic behavior matching LazyVim defaults
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.neovim-ide;
in
{
  config = mkIf cfg.enable {
    # tree-sitter CLI for grammar compilation
    home.packages = [ pkgs.tree-sitter ];

    # Use the modular luaConfig options
    programs.neovim-ide = {
      # Suppress warnings (Lua module - runs early)
      luaConfigPre."00-suppress-warnings" = ''
        require('user.core').suppress_warnings()
      '';

      # Borders and diagnostics (Lua module)
      luaConfigPost."00-borders" = ''
        require('user.core').setup()
      '';
    };

    programs.nvf.settings.vim = {

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

        # Disable tabline (we use lualine for tab info)
        showtabline = 0;
      };
    };
  };
}
