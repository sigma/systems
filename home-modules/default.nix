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
    ./mailsetup.nix
    ./settings
    ./shells
    ./tmuxp.nix
  ];

  catppuccin.enable = true;

  programs =
    {
      cloudshell.enable = true;
      fd.enable = true;
      gh.enable = true;
      gh.settings.pager = "${pkgs.delta}/bin/delta";
      gh-dash.enable = true;
      gitui.enable = true;
      jq.enable = true;
      lieer.enable = true;
      ripgrep.enable = true;
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
      wget

      # build tools
      circleci-cli
      gnumake
      goreleaser
      just
      ninja
      master.buck2
      bump2version
      mprocs
      parallel

      # console tools
      broot
      btop
      chafa
      coreutils
      d2
      glow
      gum
      hexyl
      htop
      jsonnet
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

      # git
      git-review
      pre-commit
      prs
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

      # k8s/yaml helpers
      jaq
      jsonnet
      jsonnet-bundler
      stable.mimir
      tanka
      yq
      kubectl
      kubeswitch

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

      # keyboard QMK tools
      mdloader
    ]
    ++ lib.optionals machine.features.mac [
      m-cli # useful macOS CLI commands
      afsctool
    ]
    ++ lib.optionals machine.features.music [
      maschine-hacks
    ];
}
