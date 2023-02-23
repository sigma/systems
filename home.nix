{ config, pkgs, lib, user, machine, ... }:

let
    loadSettings = prog: import ./settings/${prog}.nix {
        inherit config pkgs lib user machine;
    };
in
{
  home.stateVersion = "22.11";

  imports = [
    ./modules/zinit.nix
    ./modules/zsh-plugins
    ./modules/bat-syntaxes
    ./modules/cloud-shell.nix
  ] ++ lib.optionals machine.isWork [
    ./modules/blaze.nix
    ./modules/gcert.nix
  ] ++ lib.optionals machine.isInteractive [
    ./modules/mailsetup.nix
  ];

  accounts.email.maildirBasePath = ".mail";
  accounts.email.accounts.${user.login} = {
      primary = true;
      notmuch.enable = true;
      realName = user.name;
      address = user.email;
      aliases = user.aliases;
  };

  programs = {
    zsh = loadSettings "zsh";

    doom-emacs = loadSettings "doom-emacs";

    direnv = loadSettings "direnv";
    htop = loadSettings "htop";
    bat = loadSettings "bat";

    git = loadSettings "git";

    tmux = loadSettings "tmux";

    ssh = loadSettings "ssh";
    notmuch = loadSettings "notmuch";
    afew = loadSettings "afew";

    gitui.enable = true;
    cloudshell.enable = true;
    lieer.enable = true;
  } // lib.optionalAttrs machine.isWork {
    gcert.enable = true;
    mercurial = loadSettings "mercurial";
  } // lib.optionalAttrs machine.isInteractive {
    mailsetup.enable = true;
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
    btop
    coreutils
    d2
    exa
    fd
    fzf
    htop
    jq
    jsonnet
    less
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
    python3
    (fenix.complete.withComponents [
      "cargo"
      "clippy"
      "rust-src"
      "rustc"
      "rustfmt"
    ])
    rust-analyzer-nightly

    # network tools
    autossh
    lftp
    nmap
    prettyping

    # Useful nix related tools
    cachix
    statix
    alejandra
    comma

    nix
  ] ++ lib.optionals stdenv.isDarwin [
    m-cli # useful macOS CLI commands
    afsctool
    maschine-hacks
  ];

  # make sure our home-manager applications are dockable
  home.activation = lib.mkIf pkgs.stdenv.isDarwin {
    copyApplications = let
      apps = pkgs.buildEnv {
        name = "home-manager-applications";
        paths = config.home.packages;
        pathsToLink = "/Applications";
      };
    in lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        baseDir="$HOME/Applications/Local"
        if [ -d "$baseDir" ]; then
          rm -rf "$baseDir"
        fi
        mkdir -p "$baseDir"
        for appFile in ${apps}/Applications/*; do
          target="$baseDir/$(basename "$appFile")"
          $DRY_RUN_CMD cp ''${VERBOSE_ARG:+-v} -fHRL "$appFile" "$baseDir"
          $DRY_RUN_CMD chmod ''${VERBOSE_ARG:+-v} -R +w "$target"
        done
      '';
  };
}
