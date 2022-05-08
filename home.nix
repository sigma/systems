{ config, pkgs, lib, ... }:

{
  home.stateVersion = "22.05";

  imports = [
    ./modules/zinit.nix
  ];

  programs = {
    zsh = import ./settings/zsh.nix { inherit config; };
    git = import ./settings/git.nix { inherit config pkgs; };
    direnv = import ./settings/direnv.nix { inherit config; };
    htop = import ./settings/htop.nix { inherit config; };

    gitui.enable = true;
  };

  home.packages = with pkgs; [
    # Some basics
    bash
    coreutils
    curl
    direnv
    wget
    zsh

    # build tools
    gnumake
    ninja

    # console tools
    bat
    coreutils
    delta
    exa
    fd
    fzf
    htop
    jq
    less
    ncdu
    pinfo
    ripgrep
    silver-searcher
    skim
    tldr
    tmux
    tree

    # editors
    zile
    emacsGcc

    # git
    gitAndTools.gh
    git-review
    tig

    # languages
    go
    python

    # network tools
    autossh
    lftp
    nmap
    prettyping

    # Useful nix related tools
    cachix # adding/managing alternative binary caches hosted by Cachix
    comma
    # comma # run software from without installing it
    niv # easy dependency management for nix projects
  ] ++ lib.optionals stdenv.isDarwin [
    m-cli # useful macOS CLI commands
  ];

  # Misc configuration files --------------------------------------------------------------------{{{
}
