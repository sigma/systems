{
  pkgs,
  lib,
  machine,
  stateVersion,
  ...
}:
{
  home.stateVersion = stateVersion;

  imports = [
    ./accounts.nix
    ./aspell.nix
    ./catppuccin.nix
    ./cloud-shell.nix
    ./cursor.nix
    ./darwin-apps.nix
    ./editors
    ./gcloud.nix
    ./jujutsu.nix
    ./just.nix
    ./kubeswitch.nix
    ./mailsetup.nix
    ./open-url.nix
    ./settings
    ./shells
    ./tmuxp.nix
    ./yt-dlp.nix
  ];

  programs = {
    cloudshell.enable = true;
    fd.enable = true;
    jq.enable = true;

    gh-dash.enable = true;
    gitui.enable = true;

    thefuck.enable = true;
  };

  home.packages =
    with pkgs;
    [
      # Some basics
      bash
      coreutils
      curl
      wget

      # build tools
      circleci-cli
      gnumake
      goreleaser
      ninja
      master.buck2
      bump2version
      mprocs
      parallel

      # console tools
      broot
      btop
      chafa
      d2
      glow
      gum
      gnutar
      hexyl
      htop
      less
      pinfo
      procs
      rm-improved
      safe-rm
      silver-searcher
      skim
      soft-serve
      tealdeer
      tree

      # writing tools
      hugo
      mdbook
      mdbook-mermaid

      # git
      git-review
      pre-commit
      local.prs
      tig

      # languages
      go
      python3
      poetry
      black
      (fenix.complete.withComponents [
        "cargo"
        "clippy"
        "rust-src"
        "rustc"
        "rustfmt"
      ])
      rust-analyzer-nightly

      # json/yaml helpers
      jaq
      jsonnet
      jsonnet-bundler
      yq-go

      # network tools
      autossh
      lftp
      nmap
      prettyping

      # Useful nix related tools
      cachix
      statix
      nixfmt-rfc-style
      comma
      devenv
      fh
      master.nix-inspect

      # keyboard QMK tools
      local.mdloader

      # for voice generation
      ffmpeg
    ]
    ++ lib.optionals machine.features.mac [
      m-cli # useful macOS CLI commands
      afsctool
    ]
    ++ lib.optionals machine.features.music [
      maschine-hacks
    ]
    ++ lib.optionals (!machine.features.work) [
      # windows helpers
      innoextract
    ];
}
