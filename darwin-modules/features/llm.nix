{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.features.llm;
in
{
  options.features.llm = {
    enable = mkEnableOption "Local LLM inference (omlx backend on darwin)";
  };

  # Hybrid install:
  # - Homebrew formula via the upstream tap → CLI (`omlx serve`).
  # - Menu-bar app comes from the DMG at https://github.com/jundot/omlx/releases
  #   (no cask is published, so it stays a manual one-time drag to /Applications).
  # The menu-bar app handles autostart and is the expected runtime; the CLI is
  # available for scripting and one-offs.
  #
  # The tap repo doesn't follow the standard `homebrew-<name>` convention, so
  # the URL must be passed explicitly via `clone_target`.
  config = mkIf cfg.enable {
    homebrew.taps = [
      {
        name = "jundot/omlx";
        clone_target = "https://github.com/jundot/omlx";
      }
    ];
    homebrew.brews = [ "jundot/omlx/omlx" ];

    user.programs.aiActiveBackend = "omlx";
  };
}
