{ config, pkgs, lib, user, machine, ... }:

let
    loadSettings = prog: import ./settings/${prog}.nix {
        inherit config pkgs lib user machine;
    };
in
{
  home.stateVersion = "22.11";

  imports = [
    ./modules/blaze.nix
    ./modules/gcert.nix
    ./modules/zinit.nix
    ./modules/zsh-plugins
    ./modules/bat-syntaxes
    ./modules/editors/emacs.nix
    ./modules/cloud-shell.nix
  ];

  programs = {
    zsh = loadSettings "zsh";

    direnv = loadSettings "direnv";
    htop = loadSettings "htop";
    bat = loadSettings "bat";

    git = loadSettings "git";
    mercurial = loadSettings "mercurial";

    tmux = loadSettings "tmux";

    ssh = loadSettings "ssh";
  } // {
      gitui.enable = true;
      gcert.enable = true;
      cloudshell.enable = true;
  };

  modules.editors.emacs.enable = true;

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
    silver-searcher
    skim
    tldr
    tmux
    tree

    # editors
    zile

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
    nix
  ] ++ lib.optionals stdenv.isDarwin [
    m-cli # useful macOS CLI commands
  ];

  # Misc configuration files --------------------------------------------------------------------{{{
}
