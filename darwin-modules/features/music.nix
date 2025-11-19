{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.features.music;
in
{
  options.features.music = {
    enable = mkEnableOption "Music";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      "ableton-live-suite"
      "arturia-software-center"
      "loopback"
      "musicbrainz-picard"
      "native-access"
      "teensy"
      "x32-edit"
    ];
  };
}
