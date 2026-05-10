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
    enable = mkEnableOption "Local LLM inference";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [ "ollama-app" ];
  };
}
