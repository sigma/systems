{
  pkgs,
}:
{
  local = {
    # packages for my configs
    emacs-vanilla-config = pkgs.callPackage ./emacs-vanilla-config.nix { };
    wezterm-config = pkgs.callPackage ./wezterm-config.nix { };

    agy-hud = pkgs.callPackage ./agy-hud.nix { };
    claude-code-statusline = pkgs.callPackage ./claude-code-statusline.nix { };
    jaeger = pkgs.callPackage ./jaeger.nix { };
    mdloader = pkgs.callPackage ./mdloader.nix { };
    myrient-downloader = pkgs.callPackage ./myrient-downloader.nix { };
    no-editor = pkgs.callPackage ./no-editor.nix { };
    noctalia-ipc = pkgs.callPackage ./noctalia-ipc.nix { };
    m3ugen = pkgs.callPackage ./m3ugen.nix { };
    prs = pkgs.callPackage ./prs.nix { };
    mt32-roms = pkgs.callPackage ./mt32-roms.nix { };
    midi-session-manager = pkgs.callPackage ./midi-session-manager.nix { };
  };
}
