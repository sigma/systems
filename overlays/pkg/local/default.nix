{
  pkgs,
  nix-filter ? pkgs.nix-filter,
}:
let
  params = {
    inherit nix-filter;
  };
in
{
  local = {
    # packages for my configs
    emacs-config = pkgs.callPackage ./emacs-config.nix params;
    wezterm-config = pkgs.callPackage ./wezterm-config.nix params;

    jaeger = pkgs.callPackage ./jaeger.nix { };
    mdloader = pkgs.callPackage ./mdloader.nix { };
    prs = pkgs.callPackage ./prs.nix { };
  };
}
