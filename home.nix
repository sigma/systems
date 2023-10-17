args@{
  config,
  pkgs,
  lib,
  user,
  machine,
  ...
}: {
  home.stateVersion = "23.05";

  imports =
    [
      ./modules/zinit.nix
      ./modules/zsh-plugins
      ./modules/bat-syntaxes
      ./modules/cloud-shell.nix
      ./modules/mailsetup.nix
      ./modules/gcert.nix
      ./modules/blaze.nix
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
    ++ lib.optionals stdenvNoCC.isDarwin [
      m-cli # useful macOS CLI commands
      afsctool
      maschine-hacks
    ];

  # make sure our home-manager applications are dockable
  home.activation = lib.mkIf pkgs.stdenvNoCC.isDarwin {
    copyApplications = let
      apps = pkgs.buildEnv {
        name = "home-manager-applications";
        paths = config.home.packages;
        pathsToLink = "/Applications";
      };
    in
      lib.hm.dag.entryAfter ["writeBoundary"] ''
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
