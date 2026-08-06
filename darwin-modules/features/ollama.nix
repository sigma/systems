{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.features.ollama;
in
{
  options.features.ollama = {
    enable = mkEnableOption "Ollama local LLM inference";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [ "ollama" ];
  };
}
