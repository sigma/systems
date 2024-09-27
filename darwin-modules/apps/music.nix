{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.music;
in {
  options.programs.music = {
    enable = mkEnableOption "Music";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      "ableton-live-suite"
      "arturia-software-center"
      "loopback"
      "native-access"
      "soundsource"
      "x32-edit"
    ];
  };
}
