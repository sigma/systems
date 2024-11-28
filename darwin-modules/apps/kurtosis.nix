{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.kurtosis;
in {
  options.programs.kurtosis = {
    enable = mkEnableOption "Kurtosis";
  };

  config = mkIf cfg.enable {
    homebrew = {
      taps = [
        "kurtosis-tech/tap"
      ];
      brews = [
        "kurtosis-tech/tap/kurtosis-cli"
      ];
    };
  };
}
