{ config, pkgs, lib, ... }:

let
    loadSettings = prog: import ./settings/${prog}.nix {
        inherit config pkgs lib;
    };
in
{
  home.stateVersion = "22.05";

  imports = [
    ./modules/zinit.nix
    ./modules/zsh-plugins
    ./modules/bat-syntaxes
  ];

  programs = {
    zsh = loadSettings "zsh";
    git = loadSettings "git";
    direnv = loadSettings "direnv";
    htop = loadSettings "htop";
    bat = loadSettings "bat";
    mercurial = loadSettings "mercurial";
  } // {
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
    coreutils
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
    emacsNativeComp

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
