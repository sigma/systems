args @ {
  pkgs,
  lib,
  machine,
  stateVersion,
  isMac,
  ...
}: {
  home.stateVersion = stateVersion;

  imports = [
    ./accounts.nix
    ./blaze.nix
    ./cloud-shell.nix
    ./darwin-apps.nix
    ./editors
    ./gcert.nix
    ./mailsetup.nix
    ./zinit.nix
    ./zsh-plugins
  ];

  programs =
    (import ./settings args)
    // {
      cloudshell.enable = true;
      fd.enable = true;
      gh.enable = true;
      gh-dash.enable = true;
      gitui.enable = true;
      jq.enable = true;
      lieer.enable = true;
      thefuck.enable = true;

      # work-only
      blaze.enable = machine.isWork;
      gcert.enable = machine.isWork;
      mailsetup.enable = machine.isWork;
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
      master.buck2

      # console tools
      btop
      coreutils
      d2
      htop
      jsonnet
      less
      pinfo
      rm-improved
      safe-rm
      silver-searcher
      skim
      tldr
      tree

      # editors
      zile

      # git
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

      # windows helpers
      innoextract
    ]
    ++ lib.optionals isMac [
      m-cli # useful macOS CLI commands
      afsctool
      maschine-hacks
    ];
}
