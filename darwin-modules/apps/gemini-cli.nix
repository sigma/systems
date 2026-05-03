# Darwin module for Gemini CLI via Homebrew.
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.gemini-cli;
in
{
  options.programs.gemini-cli = {
    enable = mkEnableOption "Gemini CLI (via Homebrew)";
  };

  config = mkIf cfg.enable {
    homebrew.brews = [ "gemini-cli" ];
  };
}
