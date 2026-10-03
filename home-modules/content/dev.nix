# `dev` content feature: software development toolchain (see CONTEXT.md).
{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.features.dev.enable {
  home.packages = with pkgs; [
    # LLM tooling bundle from the toolbox: qmd, openspec, agentmemory,
    # aperture and caveman-proxy (run as a service by ../programs/caveman-proxy.nix).
    # Its skills are linked by ../settings/programs/agentSkills.nix.
    toolbox.llm-toolchain

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
  ];
}
