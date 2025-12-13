# nvf-based Neovim configuration
# Aims to replicate LazyVim experience
#
# See docs/nvf-lazyvim-roadmap.md for the full plan
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.neovim-ide;

  # Concatenate all Lua config snippets in order
  concatLuaSnippets = snippets: concatStringsSep "\n\n" (filter (s: s != "") (attrValues snippets));

  # Path to lua modules
  luaPath = ./lua;
in
{
  imports = [
    ./core.nix
    ./theme.nix
    ./keymaps.nix
    ./ui
    ./lsp
    ./navigation
    ./editing
    ./utility
  ];

  options.programs.neovim-ide = {
    enable = mkEnableOption "LazyVim-like Neovim configuration via nvf";

    # Modular Lua config options - allows multiple modules to contribute snippets
    luaConfigPre = mkOption {
      type = types.attrsOf types.lines;
      default = { };
      description = ''
        Attribute set of Lua code snippets to run before plugin setup.
        Each key is a descriptive name, value is the Lua code.
        All snippets are concatenated in alphabetical order by key.
      '';
      example = literalExpression ''
        {
          "00-suppress-warnings" = '''
            -- Suppress deprecation warnings
            vim.notify = function() end
          ''';
          "10-globals" = '''
            vim.g.some_global = true
          ''';
        }
      '';
    };

    luaConfigPost = mkOption {
      type = types.attrsOf types.lines;
      default = { };
      description = ''
        Attribute set of Lua code snippets to run after plugin setup.
        Each key is a descriptive name, value is the Lua code.
        All snippets are concatenated in alphabetical order by key.
      '';
      example = literalExpression ''
        {
          "00-borders" = '''
            -- Configure floating window borders
            vim.diagnostic.config({ float = { border = "rounded" } })
          ''';
          "10-format-on-save" = '''
            -- Format on save autocmd
            vim.api.nvim_create_autocmd("BufWritePre", { ... })
          ''';
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.nvf = {
      enable = true;

      settings.vim = {
        # Use vi/vim aliases
        viAlias = true;
        vimAlias = true;

        # Add user lua modules from nix store to package path
        luaConfigPre = ''
          -- Add user modules from nix store to package path
          package.path = "${luaPath}/?.lua;${luaPath}/?/init.lua;" .. package.path
        '' + "\n\n" + concatLuaSnippets cfg.luaConfigPre;

        # Concatenate all luaConfigPost snippets
        luaConfigPost = concatLuaSnippets cfg.luaConfigPost;

        # Enable visual features
        visuals = {
          nvim-scrollbar.enable = true;
          nvim-cursorline.enable = true;
        };

        # Enable treesitter for syntax highlighting
        treesitter = {
          enable = true;
          indent.enable = true;
          highlight.enable = true;
        };
      };
    };
  };
}
