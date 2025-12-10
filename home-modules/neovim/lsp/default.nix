# LSP module aggregator
# Imports all LSP-related configurations
{
  imports = [
    ./languages.nix
    ./completion.nix
    ./keymaps.nix
    ./trouble.nix
    ./snippets.nix
    ./fidget.nix
    ./formatting.nix
    ./lspkind.nix
    ./signature.nix
    ./dap.nix
  ];
}
