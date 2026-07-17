{
  config,
  lib,
  pkgs,
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

  # Music is Mac-only content: every channel it delivers through is macOS-only, so the
  # whole feature lives here and reads machine.features.music structurally rather than the
  # home feature seam. See docs/adr/0001-music-mac-only-content-bypasses-seam.md.
  config = mkIf cfg.enable {
    # DAWs and controller software not packaged in nixpkgs.
    homebrew.casks = [
      "ableton-live-suite"
      "arturia-software-center"
      "loopback"
      "musicbrainz-picard"
      "native-access"
      "teensy"
      "x32-edit"
    ];

    # RTP-MIDI session to the Integra-7, managed by the midi-sessions primitive.
    features.midi-sessions = {
      enable = true;
      sessions.Integra.devices = [ { name = "integra7"; } ];
    };

    # Place the NI controller apps on the music workspace.
    programs.aerospace.windowRules = [
      {
        appId = "com.native-instruments.Maschine 2";
        layout = "tiling";
        workspace = "M";
      }
      {
        appId = "com.native-instruments.Traktor";
        layout = "tiling";
        workspace = "M";
      }
    ];

    # Mac-side patch that teaches the NI software about the Maschine hardware.
    user.home.packages = with pkgs; [ maschine-hacks ];
  };
}
