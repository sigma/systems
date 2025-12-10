# Keymaps configuration
# LazyVim-style keybindings
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
      keymaps = [
        # Better window navigation
        {
          key = "<C-h>";
          mode = [ "n" ];
          action = "<C-w>h";
          desc = "Go to left window";
        }
        {
          key = "<C-j>";
          mode = [ "n" ];
          action = "<C-w>j";
          desc = "Go to lower window";
        }
        {
          key = "<C-k>";
          mode = [ "n" ];
          action = "<C-w>k";
          desc = "Go to upper window";
        }
        {
          key = "<C-l>";
          mode = [ "n" ];
          action = "<C-w>l";
          desc = "Go to right window";
        }

        # Resize windows with arrows
        {
          key = "<C-Up>";
          mode = [ "n" ];
          action = "<cmd>resize +2<cr>";
          desc = "Increase window height";
        }
        {
          key = "<C-Down>";
          mode = [ "n" ];
          action = "<cmd>resize -2<cr>";
          desc = "Decrease window height";
        }
        {
          key = "<C-Left>";
          mode = [ "n" ];
          action = "<cmd>vertical resize -2<cr>";
          desc = "Decrease window width";
        }
        {
          key = "<C-Right>";
          mode = [ "n" ];
          action = "<cmd>vertical resize +2<cr>";
          desc = "Increase window width";
        }

        # Buffer navigation
        {
          key = "<S-h>";
          mode = [ "n" ];
          action = "<cmd>bprevious<cr>";
          desc = "Previous buffer";
        }
        {
          key = "<S-l>";
          mode = [ "n" ];
          action = "<cmd>bnext<cr>";
          desc = "Next buffer";
        }
        {
          key = "<leader>bd";
          mode = [ "n" ];
          action = "<cmd>bdelete<cr>";
          desc = "Delete buffer";
        }
        {
          key = "<leader>bD";
          mode = [ "n" ];
          action = "<cmd>bdelete!<cr>";
          desc = "Delete buffer (force)";
        }

        # Clear search highlight
        {
          key = "<Esc>";
          mode = [ "n" ];
          action = "<cmd>nohlsearch<cr>";
          desc = "Clear search highlight";
        }

        # Save file
        {
          key = "<leader>w";
          mode = [ "n" ];
          action = "<cmd>w<cr>";
          desc = "Save file";
        }
        {
          key = "<C-s>";
          mode = [ "n" "i" "v" ];
          action = "<cmd>w<cr><esc>";
          desc = "Save file";
        }

        # Quit
        {
          key = "<leader>q";
          mode = [ "n" ];
          action = "<cmd>q<cr>";
          desc = "Quit";
        }
        {
          key = "<leader>Q";
          mode = [ "n" ];
          action = "<cmd>qa<cr>";
          desc = "Quit all";
        }

        # Better indenting (keep selection)
        {
          key = "<";
          mode = [ "v" ];
          action = "<gv";
          desc = "Indent left";
        }
        {
          key = ">";
          mode = [ "v" ];
          action = ">gv";
          desc = "Indent right";
        }

        # Move lines up/down
        {
          key = "<A-j>";
          mode = [ "n" ];
          action = "<cmd>m .+1<cr>==";
          desc = "Move line down";
        }
        {
          key = "<A-k>";
          mode = [ "n" ];
          action = "<cmd>m .-2<cr>==";
          desc = "Move line up";
        }
        {
          key = "<A-j>";
          mode = [ "v" ];
          action = ":m '>+1<cr>gv=gv";
          desc = "Move selection down";
        }
        {
          key = "<A-k>";
          mode = [ "v" ];
          action = ":m '<-2<cr>gv=gv";
          desc = "Move selection up";
        }

        # Better up/down (respect wrapped lines)
        {
          key = "j";
          mode = [ "n" "x" ];
          action = "v:count == 0 ? 'gj' : 'j'";
          expr = true;
          silent = true;
          desc = "Move down";
        }
        {
          key = "k";
          mode = [ "n" "x" ];
          action = "v:count == 0 ? 'gk' : 'k'";
          expr = true;
          silent = true;
          desc = "Move up";
        }

        # Add blank lines
        {
          key = "<leader>o";
          mode = [ "n" ];
          action = "o<Esc>";
          desc = "Add blank line below";
        }
        {
          key = "<leader>O";
          mode = [ "n" ];
          action = "O<Esc>";
          desc = "Add blank line above";
        }

        # Split windows
        {
          key = "<leader>-";
          mode = [ "n" ];
          action = "<cmd>split<cr>";
          desc = "Split horizontal";
        }
        {
          key = "<leader>|";
          mode = [ "n" ];
          action = "<cmd>vsplit<cr>";
          desc = "Split vertical";
        }

        # Tabs
        {
          key = "<leader><tab>l";
          mode = [ "n" ];
          action = "<cmd>tablast<cr>";
          desc = "Last tab";
        }
        {
          key = "<leader><tab>f";
          mode = [ "n" ];
          action = "<cmd>tabfirst<cr>";
          desc = "First tab";
        }
        {
          key = "<leader><tab><tab>";
          mode = [ "n" ];
          action = "<cmd>tabnew<cr>";
          desc = "New tab";
        }
        {
          key = "<leader><tab>]";
          mode = [ "n" ];
          action = "<cmd>tabnext<cr>";
          desc = "Next tab";
        }
        {
          key = "<leader><tab>[";
          mode = [ "n" ];
          action = "<cmd>tabprevious<cr>";
          desc = "Previous tab";
        }
        {
          key = "<leader><tab>d";
          mode = [ "n" ];
          action = "<cmd>tabclose<cr>";
          desc = "Close tab";
        }

        # Escape from terminal mode
        {
          key = "<Esc><Esc>";
          mode = [ "t" ];
          action = "<C-\\><C-n>";
          desc = "Exit terminal mode";
        }

        # Yank to end of line (like D and C)
        {
          key = "Y";
          mode = [ "n" ];
          action = "y$";
          desc = "Yank to end of line";
        }

        # Center cursor after jumps
        {
          key = "<C-d>";
          mode = [ "n" ];
          action = "<C-d>zz";
          desc = "Scroll down and center";
        }
        {
          key = "<C-u>";
          mode = [ "n" ];
          action = "<C-u>zz";
          desc = "Scroll up and center";
        }
        {
          key = "n";
          mode = [ "n" ];
          action = "nzzzv";
          desc = "Next search result (centered)";
        }
        {
          key = "N";
          mode = [ "n" ];
          action = "Nzzzv";
          desc = "Previous search result (centered)";
        }
      ];
    };
  };
}
