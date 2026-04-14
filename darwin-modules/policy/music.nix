{
  lib,
  machine,
  ...
}:
with lib;
{
  config = mkIf machine.features.music {
    features.midi-sessions.sessions = {
      Integra = {
        devices = [
          { name = "integra7"; }
        ];
      };
    };
  };
}
