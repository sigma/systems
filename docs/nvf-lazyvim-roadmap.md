# nvf LazyVim-like Configuration Roadmap

This document outlines the plan to create a Neovim configuration using [nvf](https://notashelf.github.io/nvf/) that replicates the features and UX of [LazyVim](https://www.lazyvim.org/).

## Goals

- Declarative, reproducible Neovim configuration via Nix
- Feature parity with LazyVim's default experience
- Clean, modular structure for easy maintenance
- Fast startup time through lazy loading

## Design Decisions

### Theme
- **Catppuccin** (frappe variant)
- Consistent theming across all UI elements

### UI Style
- **Lualine**: Rounded separators (bubble/pill style)
- Clean, minimal aesthetic matching LazyVim

### File Navigation
- **Current**: Neo-tree (LazyVim default)
- **Future**: Consider snacks.picker for speed-dial file access

### Fuzzy Finding
- **Current**: Telescope (well-supported in nvf)
- **Future**: Evaluate alternatives (fzf-lua, snacks.picker) if better options emerge

### File Marks/Quick Access
- **Candidates**:
  - Harpoon (popular, well-documented)
  - Marko (newer, reportedly excellent)
- **Decision**: Evaluate both, pick based on UX

---

## Phase 1: Foundation ✅

### 1.1 Flake Integration
- [x] Add nvf to flake.nix inputs
- [x] Create `home-modules/neovim/default.nix` module structure
- [x] Import nvf homeManagerModules

### 1.2 Core Settings
```nix
vim.options = {
  number = true;
  relativenumber = true;
  signcolumn = "yes";
  cursorline = true;
  termguicolors = true;
  clipboard = "unnamedplus";
  mouse = "a";
  undofile = true;
  smartcase = true;
  ignorecase = true;
  splitbelow = true;
  splitright = true;
  scrolloff = 8;
  sidescrolloff = 8;
  tabstop = 2;
  shiftwidth = 2;
  expandtab = true;
};

vim.globals = {
  mapleader = " ";
  maplocalleader = "\\";
};
```

### 1.3 Theme Configuration
- [x] Enable catppuccin theme with frappe variant
- [ ] Configure transparent background (optional)
- [ ] Ensure consistent colors in all UI elements

### 1.4 Basic Keymaps (LazyVim conventions)
| Key | Mode | Action | Description |
|-----|------|--------|-------------|
| `<leader>` | n | (space) | Leader key |
| `<C-h/j/k/l>` | n | Window navigate | Move between windows |
| `<C-Up/Down/Left/Right>` | n | Resize window | Resize splits |
| `<S-h>` | n | `:bprevious` | Previous buffer |
| `<S-l>` | n | `:bnext` | Next buffer |
| `<leader>bd` | n | Delete buffer | Close current buffer |
| `<leader>w` | n | `:w` | Save file |
| `<leader>q` | n | `:q` | Quit |
| `<Esc><Esc>` | n | `:noh` | Clear search highlight |
| `j/k` | n | `gj/gk` | Move by visual line |
| `<` / `>` | v | Indent | Keep selection after indent |

**Status**: ✅ All basic keymaps implemented in `keymaps.nix`

### 1.5 Additional Features Implemented
- [x] Treesitter (syntax highlighting, indent)
- [x] Visual enhancements (nvim-scrollbar, nvim-cursorline)
- [x] vi/vim aliases

---

## Phase 2: UI/UX

### 2.1 Statusline (Lualine) ✅
- [x] Enable lualine
- [x] Configure rounded/bubble separators: `component_separators` and `section_separators`
- [x] Sections:
  - Left: mode, git branch, diff
  - Center: filename
  - Right: diagnostics, filetype, encoding, location, progress

### 2.2 Bufferline ✅
- [x] Enable bufferline.nvim
- [x] Show buffer tabs at top with slant separators
- [x] Close button, modified indicator
- [x] Integration with buffer delete commands (<leader>bd)
- [x] Offset for neo-tree sidebar

### 2.3 File Explorer (Neo-tree) ✅
- [x] Enable neo-tree
- [x] Keymaps:
  - `<leader>e` - Toggle explorer
  - `<leader>E` - Reveal current file in explorer
- [x] Position: left (width 35)
- [x] Show git status, diagnostics
- [x] Follow current file, hijack netrw

### 2.4 Dashboard ✅
- [x] Enable alpha-nvim with dashboard theme
- [x] Recent files
- [x] Quick actions (new file, find file, config, quit)
- [ ] Custom header (optional)

### 2.5 Notifications ✅
- [x] Enable nvim-notify
- [x] Catppuccin-compatible styling
- [x] LSP progress handled by fidget.nvim (see 4.7) ✅

### 2.6 Indent Guides ✅
- [x] Enable indent-blankline.nvim
- [x] Show current scope (treesitter-based)
- [x] Exclude special filetypes (neo-tree, help, etc.)

### 2.7 Which-key ✅
- [x] Enable which-key.nvim
- [x] Modern preset style
- [x] Configure group labels:
  - `<leader>b` = "+buffer"
  - `<leader>c` = "+code"
  - `<leader>f` = "+file/find"
  - `<leader>g` = "+git"
  - `<leader>s` = "+search"
  - `<leader>u` = "+ui"
  - `<leader>w` = "+windows"
  - `<leader>x` = "+diagnostics"
  - `<leader><tab>` = "+tabs"

### 2.8 Additional Visual Enhancements
- [x] nvim-web-devicons ✅
- [x] dressing.nvim (better vim.ui) ✅
- [x] noice.nvim (cmdline, messages, popupmenu UI) ✅

---

## Phase 3: Navigation & Search

### 3.1 Telescope ✅
- [x] Enable telescope.nvim
- [x] Keymaps:
  - `<leader>ff` - Find files
  - `<leader>fg` - Live grep
  - `<leader>fb` - Buffers
  - `<leader>fh` - Help tags
  - `<leader>fr` - Resume last search
  - `<leader><space>` - Find files (alt)
  - `<leader>/` - Grep in project
  - `<leader>,` - Switch buffer
  - `<leader>:` - Command history
  - `<leader>ss` - Document symbols
  - `<leader>sS` - Workspace symbols
  - `<leader>sd` - Diagnostics
  - Git: `<leader>gf/gc/gb/gs`

### 3.2 Flash.nvim ✅
- [x] Enable quick jump motions
- [x] `s` - Flash jump
- [x] `S` - Flash treesitter
- [x] `r` - Remote flash
- [x] `<C-s>` - Toggle flash search

### 3.3 File Marks (Harpoon) ✅
- [x] Enable harpoon
- [x] Keymaps:
  - `<leader>a` - Add file to marks
  - `<leader>h` - Toggle quick menu
  - `<leader>1-4` - Jump to marked files

### 3.4 Todo Comments ✅
- [x] Enable todo-comments.nvim
- [x] Highlight TODO, FIXME, HACK, NOTE, etc.
- [x] `<leader>st` - Search todos (Telescope)
- [x] `<leader>xt` - Search todos (Trouble)
- [x] `<leader>xT` - Todos in quickfix

---

## Phase 4: LSP & Completion

### 4.1 LSP Configuration ✅
- [x] Enable LSP support globally
- [x] Configure languages:
  - **Nix**: nil + nixfmt formatting
  - **Lua**: lua-language-server
  - **TypeScript/JavaScript**: typescript-language-server
  - **Go**: gopls + formatting
  - **Rust**: rust-analyzer + formatting
  - **Python**: basedpyright + black formatting
  - **YAML**: yamlls
  - **Markdown**: marksman
  - **Bash**: bashls
  - **HTML/CSS**: treesitter
  - **SQL**: treesitter + sqls

### 4.2 LSP Keymaps (LazyVim conventions) ✅
| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | Go to references |
| `gI` | Go to implementation |
| `gy` | Go to type definition |
| `K` | Hover documentation |
| `gK` | Signature help |
| `<leader>ca` | Code action |
| `<leader>cr` | Rename |
| `<leader>cf` | Format |
| `<leader>cd` | Line diagnostics |
| `]d` / `[d` | Next/prev diagnostic |
| `]e` / `[e` | Next/prev error |
| `]w` / `[w` | Next/prev warning |

### 4.3 Completion (nvim-cmp) ✅
- [x] Enable nvim-cmp completion engine
- [x] Sources: LSP, buffer, path, treesitter
- [x] Keymaps:
  - `<C-Space>` - Trigger completion
  - `<CR>` - Confirm
  - `<C-e>` - Abort
  - `<Tab>` / `<S-Tab>` - Navigate items
  - `<C-b>` / `<C-f>` - Scroll docs

### 4.4 Snippets ✅
- [x] Enable LuaSnip
- [x] Load friendly-snippets (VS Code compatible)
- [x] Auto-snippets and history enabled
- [x] `<Tab>` / `<S-Tab>` - Jump placeholders ✅
- [x] `<C-l>` - Select next choice in choice nodes ✅

### 4.5 Formatting & Linting ✅
- [x] Enable format-on-save (via LSP)
- [x] Toggle format-on-save with `<leader>uf`
- [x] Configure formatters per language:
  - Nix: nixfmt
  - Go: gopls format
  - Rust: rustfmt (via rust-analyzer)
  - Python: black
  - TypeScript/JavaScript: LSP format
- [ ] Linting integration (future: nvim-lint)

### 4.6 Diagnostics UI (Trouble.nvim) ✅
- [x] Enable trouble.nvim
- [x] Keymaps:
  - `<leader>xx` - Document diagnostics
  - `<leader>xX` - Workspace diagnostics
  - `<leader>xL` - Location list
  - `<leader>xQ` - Quickfix list
  - `<leader>xr` - LSP references
  - `<leader>cs` - Symbols

### 4.7 LSP Enhancements ✅
- [x] lsp_signature.nvim - Function signature help ✅
- [x] lspkind.nvim - VSCode-like pictograms in completion ✅
- [x] nvim-navic - Breadcrumbs/winbar ✅
- [x] fidget.nvim - LSP progress indicator ✅

---

## Phase 5: Editing Enhancements

### 5.1 Treesitter ✅
- [x] Enable treesitter (enabled in Phase 1)
- [x] Grammars installed via language modules
- [x] Features: syntax highlighting, indentation

### 5.2 Text Objects & Motions ✅
- [x] mini.ai with treesitter support
- [x] Additional text objects:
  - `af/if` - Function
  - `ac/ic` - Class
  - `ao/io` - Block/conditional/loop
  - `aa/ia` - Parameter/argument

### 5.3 Autopairs ✅
- [x] Enable nvim-autopairs
- [x] Auto-close brackets, quotes

### 5.4 Comments ✅
- [x] Enable comment-nvim
- [x] `gc` - Toggle comment (operator)
- [x] `gcc` - Toggle current line

### 5.5 Surround ✅
- [x] Enable nvim-surround
- [x] Classic keybindings (ys/ds/cs)
- [x] `ys{motion}{char}` - Add surround
- [x] `ds{char}` - Delete surround
- [x] `cs{old}{new}` - Change surround

### 5.6 Git Integration ✅
- [x] gitsigns.nvim:
  - Git signs in signcolumn
  - `]h` / `[h` - Next/prev hunk
  - `<leader>ghs` - Stage hunk
  - `<leader>ghr` - Reset hunk
  - `<leader>ghp` - Preview hunk
  - `<leader>ghb` - Blame line
  - `<leader>gtb` - Toggle blame
- [ ] lazygit integration (not available in nvf)
- [x] diffview.nvim ✅
  - `<leader>gd` - Open Diffview
  - `<leader>gD` - Close Diffview
  - `<leader>gH` - File history (all)
  - `<leader>gh` - Current file history

### 5.7 Other Editing Features
- [x] mini.bufremove - Better buffer deletion ✅
- [x] persistence.nvim - Session management ✅
  - `<leader>qs` - Restore session
  - `<leader>qS` - Select session
  - `<leader>ql` - Restore last session
  - `<leader>qd` - Don't save current session
- [x] vim-illuminate - Highlight word under cursor ✅
- [ ] nvim-spectre - Search and replace (not available in nvf)

---

## Phase 6: Language-Specific Extras

These can be enabled on-demand, similar to LazyVim extras.
Note: Basic LSP, treesitter, and formatting are configured in `lsp/languages.nix`.

### 6.1 Nix ✅
- [x] nil LSP ✅
- [x] nixfmt formatting ✅
- [x] Treesitter grammar ✅

### 6.2 Go
- [x] gopls LSP ✅
- [x] Format on save ✅
- [x] gofumpt formatting ✅
- [ ] Go-specific keymaps (test, run, etc.)
- [x] nvim-dap-go for debugging (delve) ✅

### 6.3 Rust
- [x] rust-analyzer ✅
- [x] rustfmt (via rust-analyzer) ✅
- [ ] crates.nvim - Cargo.toml helper (not available in nvf)
- [x] nvim-dap for debugging ✅

### 6.4 TypeScript/JavaScript
- [x] typescript-language-server ✅
- [x] Format on save ✅
- [x] prettier formatting (via prettierd) ✅
- [x] eslint integration (via extraDiagnostics) ✅
- [ ] Package.json helper

### 6.5 Python
- [x] basedpyright LSP ✅
- [x] black formatting ✅
- [ ] isort integration
- [x] nvim-dap-python for debugging ✅
- [ ] venv-selector.nvim

### 6.6 Markdown
- [x] marksman LSP ✅
- [x] Markdown preview ✅
  - `<leader>mp` - Start browser preview
  - `<leader>ms` - Stop browser preview
  - `<leader>mt` - Toggle browser preview
  - `<leader>mg` - Glow terminal preview
- [ ] Concealing for cleaner editing

---

## Module Structure

Proposed file structure under `home-modules/neovim/`:

```
home-modules/neovim/
├── default.nix          # Main entry point, imports all modules
├── core.nix             # Core settings, options, globals
├── keymaps.nix          # All keybindings
├── theme.nix            # Catppuccin configuration
├── ui/
│   ├── default.nix      # Imports all UI modules
│   ├── lualine.nix      # Statusline
│   ├── bufferline.nix   # Buffer tabs
│   ├── neo-tree.nix     # File explorer
│   ├── dashboard.nix    # Start screen
│   └── which-key.nix    # Keybinding hints
├── navigation/
│   ├── default.nix
│   ├── telescope.nix    # Fuzzy finder
│   └── harpoon.nix      # File marks
├── lsp/
│   ├── default.nix      # LSP core config
│   ├── completion.nix   # Completion engine
│   └── trouble.nix      # Diagnostics
├── editing/
│   ├── default.nix
│   ├── treesitter.nix   # Syntax & text objects
│   ├── git.nix          # Git integration
│   └── mini.nix         # mini.nvim plugins
└── languages/
    ├── default.nix      # Common language settings
    ├── nix.nix
    ├── go.nix
    ├── rust.nix
    ├── typescript.nix
    └── python.nix
```

---

## Implementation Order

1. **Phase 1** - Get a working editor with basic settings and theme
2. **Phase 2.1-2.3** - Lualine, bufferline, neo-tree (essential UI)
3. **Phase 4.1-4.3** - LSP and completion (essential for coding)
4. **Phase 5.1-5.4** - Treesitter, autopairs, comments (essential editing)
5. **Phase 3.1** - Telescope (navigation)
6. **Phase 2.4-2.7** - Dashboard, notifications, which-key (polish)
7. **Phase 5.5-5.6** - Surround, git integration
8. **Phase 3.2-3.4** - Flash, file marks, todo comments
9. **Phase 4.4-4.7** - Snippets, formatting, LSP enhancements
10. **Phase 6** - Language-specific extras as needed

---

## References

- [nvf Manual](https://notashelf.github.io/nvf/index.xhtml)
- [nvf Options Reference](https://notashelf.github.io/nvf/options)
- [LazyVim Documentation](https://www.lazyvim.org/)
- [LazyVim Keymaps](https://www.lazyvim.org/keymaps)
- [LazyVim Plugins](https://www.lazyvim.org/plugins)

---

## Notes

- nvf uses DAG (Directed Acyclic Graph) for configuration ordering
- Use `setupOpts` API for plugin configuration (Nix attrs → Lua tables)
- `vim.lazy.plugins` for lazy-loaded plugins (v0.7+)
- Test changes with `nix run .#homeConfigurations.<host>.activationPackage`
