args@{
  pkgs,
  lib,
  user,
  machine,
  stateVersion,
  isMac,
  ...
}: {
  home.stateVersion = stateVersion;

  imports =
    [
      ./zinit.nix
      ./zsh-plugins
      ./bat-syntaxes
      ./cloud-shell.nix
      ./mailsetup.nix
      ./gcert.nix
      ./blaze.nix
      ./darwin-apps.nix
    ];

  accounts.email.maildirBasePath = ".mail";
  accounts.email.accounts.${user.login} = {
    primary = true;
    notmuch.enable = true;
    realName = user.name;
    address = user.email;
    aliases = user.aliases;
  };

  programs =
    (import ./settings args) // {
      cloudshell.enable = true;
      lieer.enable = true;
      mailsetup.enable = machine.isWork;
      gitui.enable = true;
      blaze.enable = machine.isWork;
      gcert.enable = machine.isWork;
    };

  home.packages = with pkgs;
    [
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
      eza
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
      emacs

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
    ]
    ++ lib.optionals isMac [
      m-cli # useful macOS CLI commands
      afsctool
      maschine-hacks
    ];
}
