{ config, pkgs, ... }:
{
  inherit (config.features.dev) enable;
  enableGitIntegration = true;

  # delta ships in the toolbox's vcs-toolchain bundle (home-modules/default.nix),
  # so installing `pkgs.delta` here would collide on `bin/delta` in the home
  # profile. `package` isn't nullable, so point it at the bundle — buildEnv
  # dedups the identical store path. The module resolves the binary with
  # `lib.getExe`, which on a bundle guesses `bin/vcs-toolchain`, hence the
  # merged-in `mainProgram` (same reasoning as programs/gh.nix: merge rather
  # than `overrideAttrs`, which would rebuild the join under a new path and
  # collide on every binary it ships).
  package = pkgs.toolbox.vcs-toolchain // {
    meta = pkgs.toolbox.vcs-toolchain.meta // {
      mainProgram = "delta";
    };
  };

  options = {
    navigate = true;
    hyperlinks = true;

    interactive = {
      "keep-plus-minus-markers" = false;
    };
  };
}
