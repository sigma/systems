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
    ./cloud-shell.nix
    ./darwin-apps.nix
    ./editors
    ./gcloud.nix
    ./jujutsu.nix
    ./kubeswitch.nix
    ./mailsetup.nix
    ./open-url.nix
    ./settings
    ./shells
    ./tmuxp.nix
    ./yt-dlp.nix
  ];

  # enable everything except vscode
  catppuccin.enable = true;
  catppuccin.vscode.profiles.default.enable = false;

  catppuccin.flavor = "frappe";
  catppuccin.tmux.extraConfig = ''
    set -g @catppuccin_window_status_style "rounded"
    set -g @catppuccin_window_text " #W"
    set -g @catppuccin_window_current_text " #W"
    set -g @catppuccin_window_flags "icon"
    set -g @catppuccin_window_current_number_color "#{@thm_green}"
  '';

  programs = {
    cloudshell.enable = true;
    fd.enable = true;
    jq.enable = true;
    ripgrep.enable = true;

    gh.enable = true;
    gh.settings.pager = "${pkgs.delta}/bin/delta";
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
      gnutar
      hexyl
      htop
      jsonnet
      less
      mise
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
