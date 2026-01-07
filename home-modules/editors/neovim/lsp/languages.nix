# Language-specific LSP, treesitter, and formatting configuration
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
      # Enable LSP globally
      lsp.enable = true;

      # Enable languages with LSP, treesitter, and formatting
      languages = {
        # Enable treesitter and formatting globally for all languages
        enableTreesitter = true;
        enableFormat = true;

        # Nix
        nix = {
          enable = true;
          lsp.servers = [ "nil" ];
          format.type = [ "nixfmt" ];
        };

        # Lua (for neovim config)
        lua = {
          enable = true;
          lsp.enable = true;
          treesitter.enable = true;
        };

        # Go
        go = {
          enable = true;
          lsp.enable = true;
          treesitter.enable = true;
          # Use gofumpt for stricter formatting
          format = {
            enable = true;
            type = [ "gofumpt" ];
          };
        };

        # Rust
        rust = {
          enable = true;
          lsp.enable = true;
          treesitter.enable = true;
          format.enable = true;
        };

        # TypeScript/JavaScript
        ts = {
          enable = true;
          lsp.enable = true;
          treesitter.enable = true;
          # Use prettier for formatting
          format = {
            enable = true;
            type = [ "prettierd" ];
          };
          # Enable ESLint for extra diagnostics
          extraDiagnostics.enable = true;
        };

        # Python
        python = {
          enable = true;
          lsp.enable = true;
          treesitter.enable = true;
          # Use black + isort for formatting
          format = {
            enable = true;
            type = [ "black" "isort" ];
          };
        };

        # Bash/Shell
        bash = {
          enable = true;
          lsp.enable = true;
          treesitter.enable = true;
        };

        # Markdown
        markdown = {
          enable = true;
          lsp.enable = true;
          treesitter.enable = true;
        };

        # YAML
        yaml = {
          enable = true;
          lsp.enable = true;
          treesitter.enable = true;
        };

        # HTML
        html = {
          enable = true;
          treesitter.enable = true;
        };

        # CSS
        css = {
          enable = true;
          treesitter.enable = true;
        };

        # SQL
        sql = {
          enable = true;
          treesitter.enable = true;
        };
      };
    };
  };
}
