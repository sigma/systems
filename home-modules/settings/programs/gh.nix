{ config, pkgs, ... }:
{
  inherit (config.features.dev) enable;

  # `package` is not nullable here, so point it at the bundle that already
  # provides `bin/gh`: buildEnv dedups the identical store path. The module's
  # account-migration activation step resolves the binary with `lib.getExe`,
  # which on a bundle guesses `bin/vcs-toolchain` — so name the main program.
  # Merged in rather than `overrideAttrs`-ed because the latter rebuilds the
  # symlinkJoin under a new store path, which would then collide with the
  # bundle proper on every single binary it ships.
  package = pkgs.toolbox.vcs-toolchain // {
    meta = pkgs.toolbox.vcs-toolchain.meta // {
      mainProgram = "gh";
    };
  };

  # delta comes from the same bundle — referencing it here rather than
  # `pkgs.delta` keeps a second delta out of the closure.
  settings.pager = "${pkgs.toolbox.vcs-toolchain}/bin/delta";
}
