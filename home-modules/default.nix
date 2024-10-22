{
  pkgs,
  lib,
  machine,
  stateVersion,
  ...
}: {
  home.stateVersion = stateVersion;

  imports = [
    ./accounts.nix
    ./cloud-shell.nix
    ./darwin-apps.nix
    ./editors
    ./gcloud.nix
    ./google.nix
    ./mailsetup.nix
    ./settings
    ./shells
    ./tmuxp.nix
  ];

  programs =
    {
      cloudshell.enable = true;
      fd.enable = true;
      gh.enable = true;
      gh-dash.enable = true;
      gitui.enable = true;
      jq.enable = true;
      lieer.enable = true;
      thefuck.enable = true;
    }
    // lib.optionalAttrs machine.features.work {
      # work-only
      mailsetup.enable = true;
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
      bump2version

      # console tools
      broot
      btop
      chafa
      coreutils
      d2
      hexyl
      htop
      jsonnet
      less
      pinfo
      procs
      ripgrep
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
      pre-commit
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

      # k8s/yaml helpers
      jsonnet
      jsonnet-bundler
      tanka
      yq

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
      devenv

      # windows helpers
      innoextract
    ]
    ++ lib.optionals machine.features.mac [
      m-cli # useful macOS CLI commands
      afsctool
    ]
    ++ lib.optionals machine.features.music [
      maschine-hacks
    ];
}
