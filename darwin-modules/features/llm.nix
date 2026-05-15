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
    enable = mkEnableOption "Local LLM inference (LM Studio on darwin)";
  };

  # GUI-driven workflow: LM Studio.app exposes an OpenAI-compatible server
  # at http://localhost:1234. After install, launch the app, toggle the
  # server on under the Developer tab, and enable "Start server when app
  # starts" so it persists across launches. Models are fetched via the
  # app's Discover tab (GGUF format) and live under ~/.lmstudio/models/.
  #
  # For headless / launchd autostart, run `lms server start` from a
  # `launchd.user.agents` block instead; not wired here because the GUI
  # path is sufficient for current use.
  config = mkIf cfg.enable {
    homebrew.casks = [ "lm-studio" ];

    user.programs.aiActiveBackend = "lmstudio";
  };
}
