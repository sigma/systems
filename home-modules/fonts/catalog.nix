# Font catalog: maps a logical key to a (package, family-name) pair.
# `family` is the user-visible name fontconfig/CoreText resolves the package
# under. Add new entries here when you need to reference a new package.
{ pkgs }:
{
  fira-code = {
    package = pkgs.fira-code;
    family = "Fira Code";
  };
  fira-code-nerd = {
    package = pkgs.master.nerd-fonts.fira-code;
    family = "FiraCode Nerd Font";
  };
  sauce-code-pro-nerd = {
    package = pkgs.master.nerd-fonts.sauce-code-pro;
    family = "SauceCodePro Nerd Font Mono";
  };
  intone-mono-nerd = {
    package = pkgs.master.nerd-fonts.intone-mono;
    family = "IntoneMono Nerd Font Mono";
  };
}
