# lspkind.nvim configuration
# VSCode-like pictograms for LSP completion items
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.neovim-ide;
  icons = import ../icons.nix;
in
{
  config = mkIf cfg.enable {
    programs.nvf.settings.vim.lsp.lspkind = {
      enable = true;
      setupOpts = {
        # Show symbol and text for completion items
        mode = "symbol_text";

        # Custom symbols from icons.nix
        symbol_map = {
          Array = icons.kinds.array;
          Boolean = icons.kinds.boolean;
          Class = icons.kinds.class;
          Codeium = icons.kinds.codeium;
          Color = icons.kinds.color;
          Constant = icons.kinds.constant;
          Constructor = icons.kinds.constructor;
          Copilot = icons.kinds.copilot;
          Enum = icons.kinds.enum;
          EnumMember = icons.kinds.enumMember;
          Event = icons.kinds.event;
          Field = icons.kinds.field;
          File = icons.kinds.file;
          Folder = icons.kinds.folder;
          Function = icons.kinds.function;
          Interface = icons.kinds.interface;
          Key = icons.kinds.key;
          Keyword = icons.kinds.keyword;
          Method = icons.kinds.method;
          Module = icons.kinds.module;
          Namespace = icons.kinds.namespace;
          Null = icons.kinds.null;
          Number = icons.kinds.number;
          Object = icons.kinds.object;
          Operator = icons.kinds.operator;
          Package = icons.kinds.package;
          Property = icons.kinds.property;
          Reference = icons.kinds.reference;
          Snippet = icons.kinds.snippet;
          String = icons.kinds.string;
          Struct = icons.kinds.struct;
          Supermaven = icons.kinds.supermaven;
          TabNine = icons.kinds.tabnine;
          Text = icons.kinds.text;
          TypeParameter = icons.kinds.typeParameter;
          Unit = icons.kinds.unit;
          Value = icons.kinds.value;
        };
      };
    };
  };
}
