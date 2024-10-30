{
  pkgs,
  nix-filter ? pkgs.nix-filter,
}: let
  params = {
    inherit nix-filter;
  };
in {
  emacs-config = pkgs.callPackage ./emacs-config.nix params;

  mdloader = pkgs.callPackage ./mdloader.nix {};

  prs = pkgs.callPackage ./prs.nix {};

  wezterm-config = pkgs.callPackage ./wezterm-config.nix params;
}
