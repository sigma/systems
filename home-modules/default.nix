{
  pkgs,
  lib,
  machine,
  stateVersion,
  ...
}:
{
  home.stateVersion = stateVersion;

  imports =
    [
      # Always included
      ./builder-access.nix
      ./catppuccin.nix
      ./editors
      ./jujutsu.nix
      ./settings
      ./shells
    ]
    ++ lib.optionals (!machine.features.devbox) [
      # Full workstation modules (skip on devboxes)
      ./accounts.nix
      ./ai
      ./aspell.nix
      ./antigravity.nix
      ./claude-firefly.nix
      ./claude-glm.nix
      ./cloud-shell.nix
      ./cursor.nix
      ./dosbox.nix
      ./darwin-apps.nix
      ./fonts
      ./gcloud.nix
      ./just.nix
      ./kew.nix
      ./kubeswitch.nix
      ./mailsetup.nix
      ./open-url.nix
      ./opencode-firefly.nix
      ./policy
      ./tmuxp.nix
      ./yt-dlp.nix
    ];

  programs = {
    fd.enable = true;
    jq.enable = true;

    neovim-ide.enable = true;
  } // lib.optionalAttrs (!machine.features.devbox) {
    cloudshell.enable = true;
    gh-dash.enable = true;
  };

  home.packages =
    with pkgs;
    [
      # Core (always included)
      bash
      coreutils
      curl
      wget
      gnumake
      gnutar
      htop
      less
      tree

      # json/yaml helpers
      jaq
      yq-go

      # work management
      toolbox.beadwork

      # Useful nix related tools
      cachix
      nixfmt
      home-manager
      nix-output-monitor
    ]
    ++ lib.optionals (!machine.features.devbox) [
      # build tools
      circleci-cli
      goreleaser
      ninja
      master.buck2
      bump2version
      mprocs
      parallel

      # console tools
      ast-grep
      broot
      btop
      chafa
      d2
      glow
      gum
      hexyl
      pinfo
      procs
      rm-improved
      safe-rm
      silver-searcher
      skim
      soft-serve
      tealdeer

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
      jsonnet
      jsonnet-bundler

      # network tools
      autossh
      lftp
      nmap
      prettyping

      # more nix tools
      statix
      comma
      master.devenv
      fh
      master.nix-inspect
      nh

      # keyboard QMK tools
      local.mdloader

      # media tools
      ffmpeg
      local.m3ugen
    ]
    ++ lib.optionals machine.features.mac [
      m-cli # useful macOS CLI commands
    ]
    ++ lib.optionals (!machine.features.mac && !machine.features.devbox) (
      let
        bun = if machine.features.nehalem then pkgs.toolbox.bun-baseline else pkgs.toolbox.bun;
      in
      [
        bun
        # Use bun-baseline on CPUs without AVX2 (pre-Haswell)
        (pkgs.master.opencode.override { inherit bun; })
      ]
    )
    ++ lib.optionals machine.features.music [
      maschine-hacks
    ]
    ++ lib.optionals machine.features.gaming [
      local.myrient-downloader
    ];
}
