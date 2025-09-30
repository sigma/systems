{
  pkgs,
}:
{
  local = {
    # packages for my configs
    emacs-config = pkgs.callPackage ./emacs-config.nix { };
    wezterm-config = pkgs.callPackage ./wezterm-config.nix { };

    jaeger = pkgs.callPackage ./jaeger.nix { };
    mdloader = pkgs.callPackage ./mdloader.nix { };
    prs = pkgs.callPackage ./prs.nix { };
  };
}
