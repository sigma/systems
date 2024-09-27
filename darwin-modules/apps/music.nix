{
  config,
  lib,
  ...
}: let
  cfg = config.programs.music;
in {
  options.programs.music = {
    enable = mkEnableOption "Music";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      "arturia-software-center"
      "loopback"
      "native-access"
      "soundsource"
      "x32-edit"
    ];
  };
}
