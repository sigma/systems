# Neovim Configuration Cheatsheet

This configuration is built with [nvf](https://github.com/NotAShelf/nvf) and aims to replicate the LazyVim experience.

## Mode Legend

| Mode | Description |
|------|-------------|
| `n` | Normal mode |
| `i` | Insert mode |
| `v` | Visual mode |
| `x` | Visual block mode |
| `s` | Select mode |
| `o` | Operator-pending mode |
| `t` | Terminal mode |
| `c` | Command-line mode |

## Leader Keys

| Key | Purpose |
|-----|---------|
| `<Space>` | Leader key |
| `\` | Local leader key |

---

## WezTerm Integration (Smart Splits)

Seamless navigation between Neovim splits and WezTerm panes using `Cmd+Arrow` keys in WezTerm.

| Mode | Key (WezTerm) | Action |
|------|---------------|--------|
| `n` | `Cmd+Left` | Move to left split/pane |
| `n` | `Cmd+Right` | Move to right split/pane |
| `n` | `Cmd+Up` | Move to upper split/pane |
| `n` | `Cmd+Down` | Move to lower split/pane |

### Resize Splits

| Mode | Key | Action |
|------|-----|--------|
| `n` | `<M-C-S-Left>` | Resize split left |
| `n` | `<M-C-S-Right>` | Resize split right |
| `n` | `<M-C-S-Up>` | Resize split up |
| `n` | `<M-C-S-Down>` | Resize split down |

### Swap Buffers

| Mode | Key | Action |
|------|-----|--------|
| `n` | `<leader>wh` | Swap buffer left |
| `n` | `<leader>wj` | Swap buffer down |
| `n` | `<leader>wk` | Swap buffer up |
| `n` | `<leader>wl` | Swap buffer right |

---

## Window Navigation

| Mode | Key | Action |
|------|-----|--------|
| `n` | `<C-h>` | Go to left window |
| `n` | `<C-j>` | Go to lower window |
| `n` | `<C-k>` | Go to upper window |
| `n` | `<C-l>` | Go to right window |
| `n` | `<C-Up>` | Increase window height |
| `n` | `<C-Down>` | Decrease window height |
| `n` | `<C-Left>` | Decrease window width |
| `n` | `<C-Right>` | Increase window width |
| `n` | `<leader>-` | Horizontal split |
| `n` | `<leader>\|` | Vertical split |

---

## Buffer Management

| Mode | Key | Action |
|------|-----|--------|
| `n` | `<S-h>` | Previous buffer |
| `n` | `<S-l>` | Next buffer |
| `n` | `<leader>bd` | Delete buffer |
| `n` | `<leader>bD` | Force delete buffer |
| `n` | `<leader>bp` | Pick buffer from bufferline |
| `n` | `<leader>bsd` | Sort buffers by directory |
| `n` | `<leader>bse` | Sort buffers by extension |

---

## Tab Management

Tabs are used as workspaces, typically one per project. Tabs auto-name based on the current project.

| Mode | Key | Action |
|------|-----|--------|
| `n` | `<leader><tab>n` | New tab |
| `n` | `<leader><tab>c` | Close tab |
| `n` | `<leader><tab>]` | Next tab |
| `n` | `<leader><tab>[` | Previous tab |
| `n` | `<leader><tab>l` | Last tab |
| `n` | `<leader><tab>f` | First tab |
| `n` | `<leader><tab>r` | Rename tab |
| `n` | `<leader><tab>1-9` | Go to tab 1-9 |
| `n` | `<leader>ft` | Find tabs (Telescope) |

---

## File Explorer (Neo-tree)

| Mode | Key | Action |
|------|-----|--------|
| `n` | `<leader>e` | Toggle file explorer |
| `n` | `<leader>E` | Reveal current file in explorer |

---

## Projects

Projects are auto-discovered from `~/src/{github.com,gitlab.com,bitbucket.org}/**/` directories.

| Mode | Key | Action |
|------|-----|--------|
| `n` | `<leader>fp` | Find projects (switch in current tab) |
| `n` | `<leader>fP` | Find projects (open in new tab) |
| `n` | `<leader>,` | Switch buffer (project-scoped) |
| `n` | `<leader>fb` | Find buffers (project-scoped) |

In the project buffer picker, `<C-d>` deletes the selected buffer.

---

## Fuzzy Finding (Telescope)

| Mode | Key | Action |
|------|-----|--------|
| `n` | `<leader><space>` | Find files |
| `n` | `<leader>/` | Live grep (search in project) |
| `n` | `<leader>:` | Command history |
| `n` | `<leader>ff` | Find files |
| `n` | `<leader>fg` | Live grep |
| `n` | `<leader>fh` | Help tags |
| `n` | `<leader>fr` | Resume last search |

### Search Commands

| Mode | Key | Action |
|------|-----|--------|
| `n` | `<leader>sg` | Grep search |
| `n` | `<leader>sw` | Grep word under cursor |
| `n` | `<leader>sr` | Resume last search |
| `n` | `<leader>ss` | Document symbols (LSP) |
| `n` | `<leader>sS` | Workspace symbols (LSP) |
| `n` | `<leader>sd` | Diagnostics |
| `n` | `<leader>st` | Todo comments |

---

## Quick File Navigation (Harpoon)

| Mode | Key | Action |
|------|-----|--------|
| `n` | `<leader>H` | Add file to harpoon list |
| `n` | `<leader>h` | Show harpoon list |
| `n` | `<leader>1` | Jump to harpoon file 1 |
| `n` | `<leader>2` | Jump to harpoon file 2 |
| `n` | `<leader>3` | Jump to harpoon file 3 |
| `n` | `<leader>4` | Jump to harpoon file 4 |

---

## AI Assistant (Claude Code)

Integration with Claude Code CLI for AI-assisted development.

| Mode | Key | Action |
|------|-----|--------|
| `n` | `<leader>ac` | Toggle Claude terminal |
| `n` | `<leader>af` | Focus Claude terminal |
| `n` | `<leader>ar` | Resume Claude session |
| `n` | `<leader>aC` | Continue Claude session |
| `n` | `<leader>am` | Select Claude model |
| `n` | `<leader>ab` | Add current buffer to context |
| `v` | `<leader>as` | Send selection to Claude |
| `n` | `<leader>aa` | Accept diff |
| `n` | `<leader>ad` | Deny diff |

In file explorer (Neo-tree), `<leader>as` adds the selected file to Claude context.

---

## Flash Navigation

| Mode | Key | Action |
|------|-----|--------|
| `n`, `x`, `o` | `s` | Flash jump (quick jump to character) |
| `n`, `x`, `o` | `S` | Flash treesitter (jump using syntax tree) |
| `o` | `r` | Remote flash (operator-pending mode) |
| `o`, `x` | `R` | Remote treesitter |
| `c` | `<C-s>` | Toggle flash |

---

## Basic Editing

| Mode | Key | Action |
|------|-----|--------|
| `n`, `i`, `v` | `<C-s>` | Save file |
| `n` | `<leader>w` | Save file |
| `n` | `<leader>q` | Quit |
| `n` | `<leader>Q` | Quit all |
| `n` | `Y` | Yank to end of line |
| `n` | `<Esc>` | Clear search highlight |

### Line Operations

| Mode | Key | Action |
|------|-----|--------|
| `n` | `<A-j>` | Move line down |
| `n` | `<A-k>` | Move line up |
| `v` | `<A-j>` | Move selection down |
| `v` | `<A-k>` | Move selection up |
| `n` | `<leader>o` | Add blank line below |
| `n` | `<leader>O` | Add blank line above |

### Visual Mode

| Mode | Key | Action |
|------|-----|--------|
| `v` | `<` | Indent left (keep selection) |
| `v` | `>` | Indent right (keep selection) |

### Scroll and Center

| Mode | Key | Action |
|------|-----|--------|
| `n` | `<C-d>` | Page down (centered) |
| `n` | `<C-u>` | Page up (centered) |
| `n` | `n` | Next search result (centered) |
| `n` | `N` | Previous search result (centered) |

---

## Comments

Uses `comment.nvim` with `gc` operator:

| Mode | Key | Action |
|------|-----|--------|
| `n` | `gcc` | Toggle comment on line |
| `n` | `gc{motion}` | Toggle comment over motion |
| `n` | `gcap` | Toggle comment on paragraph |
| `v` | `gc` | Toggle comment on selection |

---

## Surround

Uses `nvim-surround`:

| Mode | Key | Action |
|------|-----|--------|
| `n` | `ys{motion}{char}` | Add surround (e.g., `ysiw"` surrounds word with quotes) |
| `n` | `ds{char}` | Delete surround (e.g., `ds"` removes surrounding quotes) |
| `n` | `cs{old}{new}` | Change surround (e.g., `cs"'` changes `"` to `'`) |
| `v` | `S{char}` | Surround selection |

---

## LSP

### Navigation

| Mode | Key | Action |
|------|-----|--------|
| `n` | `gd` | Go to definition |
| `n` | `gD` | Go to declaration |
| `n` | `gr` | Go to references |
| `n` | `gI` | Go to implementation |
| `n` | `gy` | Go to type definition |
| `n` | `K` | Hover documentation |
| `n` | `gK` | Signature help |
| `i` | `<C-k>` | Signature help |

### Code Actions

| Mode | Key | Action |
|------|-----|--------|
| `n`, `v` | `<leader>ca` | Code action |
| `n` | `<leader>cr` | Rename symbol |
| `n`, `v` | `<leader>cf` | Format buffer/selection |
| `n` | `<leader>cd` | Line diagnostics |
| `n` | `<leader>cl` | Lint current file |

### Diagnostics Navigation

| Mode | Key | Action |
|------|-----|--------|
| `n` | `]d` | Next diagnostic |
| `n` | `[d` | Previous diagnostic |
| `n` | `]e` | Next error |
| `n` | `[e` | Previous error |
| `n` | `]w` | Next warning |
| `n` | `[w` | Previous warning |

### Trouble (Diagnostics List)

| Mode | Key | Action |
|------|-----|--------|
| `n` | `<leader>xx` | Document diagnostics |
| `n` | `<leader>xX` | Workspace diagnostics |
| `n` | `<leader>xr` | LSP references |
| `n` | `<leader>xQ` | Quickfix list |
| `n` | `<leader>xL` | Location list |
| `n` | `<leader>xT` | Todos in quickfix |
| `n` | `<leader>xt` | Todos in trouble |
| `n` | `<leader>cs` | Symbols (trouble) |

---

## Completion

| Mode | Key | Action |
|------|-----|--------|
| `i` | `<C-Space>` | Trigger completion |
| `i` | `<CR>` | Confirm selection |
| `i` | `<Tab>` | Next item / expand snippet |
| `i` | `<S-Tab>` | Previous item |
| `i` | `<C-e>` | Close completion menu |
| `i` | `<C-b>` | Scroll docs up |
| `i` | `<C-f>` | Scroll docs down |

### Snippets

| Mode | Key | Action |
|------|-----|--------|
| `i`, `s` | `<Tab>` | Expand snippet or jump to next placeholder |
| `i`, `s` | `<S-Tab>` | Jump to previous placeholder |
| `i`, `s` | `<C-l>` | Next snippet choice |

---

## Git

### Hunk Navigation (Gitsigns)

| Mode | Key | Action |
|------|-----|--------|
| `n` | `]h` | Next hunk |
| `n` | `[h` | Previous hunk |

### Hunk Operations

| Mode | Key | Action |
|------|-----|--------|
| `n` | `<leader>ghs` | Stage hunk |
| `n` | `<leader>ghS` | Stage buffer |
| `n` | `<leader>ghu` | Undo stage hunk |
| `n` | `<leader>ghr` | Reset hunk |
| `n` | `<leader>ghR` | Reset buffer |
| `n` | `<leader>ghp` | Preview hunk |
| `n` | `<leader>ghb` | Blame line |
| `n` | `<leader>gtb` | Toggle blame |
| `n` | `<leader>ghd` | Diff hunk |
| `n` | `<leader>ghD` | Diff project |
| `v` | `<leader>ghs` | Stage selected hunk |
| `v` | `<leader>ghr` | Reset selected hunk |

### Git Telescope

| Mode | Key | Action |
|------|-----|--------|
| `n` | `<leader>gf` | Git files |
| `n` | `<leader>gc` | Git commits |
| `n` | `<leader>gb` | Git branches |
| `n` | `<leader>gs` | Git status |

### Diffview

| Mode | Key | Action |
|------|-----|--------|
| `n` | `<leader>gd` | Open diffview |
| `n` | `<leader>gD` | Close diffview |
| `n` | `<leader>gH` | Full file history |
| `n` | `<leader>gh` | Current file history |

### LazyGit

| Mode | Key | Action |
|------|-----|--------|
| `n` | `<leader>gg` | Open lazygit |
| `n` | `<leader>gG` | Lazygit for current file |

---

## Debugging (DAP)

### Session Control

| Mode | Key | Action |
|------|-----|--------|
| `n` | `<leader>dc` | Start/continue |
| `n` | `<leader>dR` | Restart |
| `n` | `<leader>dq` | Terminate |
| `n` | `<leader>d.` | Run last configuration |
| `n` | `<leader>dr` | Toggle REPL |
| `n` | `<leader>du` | Toggle DAP UI |

### Stepping

| Mode | Key | Action |
|------|-----|--------|
| `n` | `<leader>di` | Step into |
| `n` | `<leader>do` | Step out |
| `n` | `<leader>dn` | Step over |
| `n` | `<leader>dk` | Step back |
| `n` | `<leader>dU` | Go up in stack |
| `n` | `<leader>dD` | Go down in stack |

### Breakpoints

| Mode | Key | Action |
|------|-----|--------|
| `n` | `<leader>db` | Toggle breakpoint |
| `n` | `<leader>dC` | Run to cursor |
| `n`, `v` | `<leader>dh` | Hover (evaluate expression) |

---

## Markdown

| Mode | Key | Action |
|------|-----|--------|
| `n` | `<leader>mp` | Start markdown preview (browser) |
| `n` | `<leader>ms` | Stop markdown preview |
| `n` | `<leader>mt` | Toggle markdown preview |
| `n` | `<leader>mg` | Glow preview (terminal) |

---

## UI Toggles

| Mode | Key | Action |
|------|-----|--------|
| `n` | `<leader>uf` | Toggle format on save |

---

## Terminal

| Mode | Key | Action |
|------|-----|--------|
| `t` | `<Esc><Esc>` | Exit terminal mode |

---

## Which-Key Group Prefixes

Press these prefixes in normal mode and wait to see available commands:

| Prefix | Group |
|--------|-------|
| `<leader>a` | AI (Claude Code) |
| `<leader>b` | Buffer |
| `<leader>c` | Code/LSP |
| `<leader>d` | Debug |
| `<leader>f` | File/Find |
| `<leader>g` | Git |
| `<leader>m` | Markdown |
| `<leader>s` | Search |
| `<leader>u` | UI toggles |
| `<leader>w` | Window/Swap |
| `<leader>x` | Diagnostics |
| `<leader><tab>` | Tabs |

---

## Enabled Plugins

| Plugin | Purpose |
|--------|---------|
| neo-tree | File explorer |
| telescope | Fuzzy finder |
| flash.nvim | Smart jump motions |
| harpoon | Quick file marks |
| project.nvim | Project management |
| smart-splits.nvim | WezTerm pane integration |
| image.nvim | Image preview (WezTerm) |
| claudecode.nvim | Claude AI integration |
| todo-comments | TODO/FIXME highlighting |
| nvim-cmp | Autocompletion |
| LuaSnip | Snippets |
| gitsigns | Git signs and hunk operations |
| comment.nvim | Comment toggling |
| nvim-surround | Surround operations |
| mini.bufremove | Better buffer deletion |
| diffview.nvim | Git diff viewer |
| lazygit.nvim | Lazygit integration |
| nvim-dap | Debugging |
| trouble.nvim | Diagnostics list |
| markdown-preview | Browser markdown preview |
| glow.nvim | Terminal markdown preview |
| which-key | Keybinding hints |
| lualine | Status line |
| noice.nvim | Enhanced UI |
| indent-blankline | Indentation guides |
| nvim-notify | Notifications |
| nvim-navic | Breadcrumbs/winbar |
