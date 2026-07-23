{
  config,
  pkgs,
  lib,
  machine,
  stateVersion,
  ...
}:
{
  home.stateVersion = stateVersion;

  imports = [
    # Always included — these declare options that other (always-loaded)
    # modules reference. Their config blocks are gated on cfg.enable, which
    # defaults to false on devbox (the corresponding settings file isn't
    # loaded), so promotion costs only the option declaration.
    ./antigravity.nix
    ./aspell.nix
    ./builder-access.nix
    ./catppuccin.nix
    # Claude Code skill mechanism — always imported so its option is declared;
    # self-gates on config.programs.claude-code.enable (true on devboxes too,
    # via nixos-modules/dev.nix). Configured in
    # ./settings/programs/{claude-code,claude-skills}.nix.
    ./claude-skills.nix
    # Composable Claude Code statusline — always imported so
    # programs.claudeStatusline is declared (voice.nix contributes a segment via
    # user.*). Self-gates on config.programs.claude-code.enable.
    ./claude-statusline.nix
    ./cursor.nix # referenced from settings/programs/jujutsu.nix
    ./editors
    ./features.nix # declares options.features.<n>.enable (content-feature seam)
    ./hunk.nix
    ./jujutsu.nix
    ./policy # gates internally on machine.features.<x>
    ./settings
    ./shells
    ./television.nix # Ctrl+R hand-off to atuin; gates on programs.television.enable
    ./tmuxp.nix # referenced from settings/programs/tmux.nix
    # Content-gated modules — always imported so their options are declared;
    # each self-gates its config on config.features.<x>.enable or on its own
    # programs.<name>.enable (set by a policy/feature), so the devbox policy's
    # mkForce on the content-feature seam is what keeps them off devboxes.
    ./accounts.nix
    ./ai # self-gates config on config.features.ai.enable
    ./claude-firefly.nix # enabled by policy/firefly.nix (machine.features.firefly)
    ./claude-glm.nix
    ./cloud-shell.nix
    ./dosbox.nix
    ./fonts
    ./gcloud.nix # enabled by policy/firefly.nix
    ./just.nix
    ./kew.nix
    ./kubeswitch.nix
    ./mailsetup.nix
    ./open-url.nix
    ./opencode-firefly.nix
    ./yt-dlp.nix
  ]
  ++ lib.optionals machine.features.mac [
    ./darwin-apps.nix # references darwin apps; mac is structural (import-time)
  ];

  programs = {
    fd.enable = true;
    jq.enable = true;

    neovim-ide.enable = true;
  }
  // lib.optionalAttrs config.features.dev.enable {
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

      # vcs management
      toolbox.entire

      # Useful nix related tools
      cachix
      nixfmt
      home-manager
      nix-output-monitor
    ]
    ++ lib.optionals config.features.dev.enable [
      # build tools
      circleci-cli
      goreleaser
      ninja
      master.buck2
      bump2version
      mprocs
      parallel

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

      # nix tools
      statix
      comma
      master.devenv
      fh
      master.nix-inspect
      nh
    ]
    ++ lib.optionals config.features.shell.enable [
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
      soft-serve
      tealdeer

      # json/yaml helpers
      jsonnet
      jsonnet-bundler
    ]
    ++ lib.optionals config.features.writing.enable [
      hugo
      mdbook
      mdbook-mermaid
    ]
    ++ lib.optionals config.features.network.enable [
      autossh
      lftp
      nmap
      prettyping
    ]
    ++ lib.optionals config.features.keyboard.enable [
      local.mdloader # QMK
    ]
    ++ lib.optionals config.features.media.enable [
      ffmpeg
      local.m3ugen
    ]
    ++ lib.optionals machine.features.mac [
      m-cli # useful macOS CLI commands
    ]
    ++ lib.optionals (config.features.ai.enable && !machine.features.mac) (
      let
        bun = if machine.features.nehalem then pkgs.toolbox.bun-baseline else pkgs.toolbox.bun;
      in
      [
        bun
        # Use bun-baseline on CPUs without AVX2 (pre-Haswell)
        (pkgs.master.opencode.override { inherit bun; })
      ]
    )
    ++ lib.optionals config.features.gaming.enable [
      local.myrient-downloader
    ];
}
