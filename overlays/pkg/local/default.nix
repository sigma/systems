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
    myrient-downloader = pkgs.callPackage ./myrient-downloader.nix { };
    noctalia-ipc = pkgs.callPackage ./noctalia-ipc.nix { };
    prs = pkgs.callPackage ./prs.nix { };
    mt32-roms = pkgs.callPackage ./mt32-roms.nix { };
  };
}
