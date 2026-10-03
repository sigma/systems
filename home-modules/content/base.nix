# Base floor: home content every machine carries, devboxes included (see
# CONTEXT.md). Never gated on a content feature.
{
  lib,
  machine,
  pkgs,
  ...
}:
{
  programs = {
    fd.enable = true;
    jq.enable = true;

    neovim-ide.enable = true;
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

      # vcs management — one bundle instead of a pile of per-tool installs.
      # vcs-toolchain ships git, git-lfs, jj, jjui, jj-hunk, gh, gh-aw,
      # gh-stack, delta, difftastic, entire, hunk and tuicr, all pinned
      # together by the toolbox. Taking the bundle means the individual
      # installs it subsumes have to be switched off or they collide on the
      # same `bin/` names — see the notes at each site.
      toolbox.vcs-toolchain

      # Useful nix related tools
      cachix
      nixfmt
      home-manager
      nix-output-monitor
    ]
    ++ lib.optionals machine.features.mac [
      m-cli # useful macOS CLI commands
    ];
}
