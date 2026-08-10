{ pkgs, ... }:
{
  fonts.packages =
    with pkgs;
    [
      fira-code
      fira-code-symbols
      lato
      recursive
      source-code-pro
    ]
    ++ (with master.nerd-fonts; [
      fira-code
      sauce-code-pro
      intone-mono
      symbols-only
    ]);
}
