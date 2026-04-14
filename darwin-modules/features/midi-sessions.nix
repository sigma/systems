{
  config,
  lib,
  pkgs,
  machine,
  user,
  ...
}:
with lib;
let
  cfg = config.features.midi-sessions;
  hostname = machine.hostKey;
  logDir = "/Users/${user.login}/Library/Logs";

  deviceType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Bonjour service name of the remote RTP-MIDI device";
      };
      host = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Static IP/hostname (bypasses Bonjour discovery)";
      };
      port = mkOption {
        type = types.nullOr types.port;
        default = null;
        description = "Static port (used with static host)";
      };
    };
  };

  sessionType = types.submodule (
    { name, ... }:
    {
      options = {
        localName = mkOption {
          type = types.str;
          default = name;
          description = "Local name of the MIDI network session (as shown in Audio MIDI Setup)";
        };
        networkName = mkOption {
          type = types.str;
          default = "${hostname}-${toLower name}";
          description = "Bonjour network name advertised for this session";
        };
        port = mkOption {
          type = types.port;
          default = 5004;
          description = "UDP port for the RTP-MIDI session";
        };
        devices = mkOption {
          type = types.listOf deviceType;
          default = [ ];
          description = "Remote devices to auto-connect to this session";
        };
      };
    }
  );

  configJSON = pkgs.writeText "midi-session-manager.json" (builtins.toJSON {
    inherit hostname;
    pollInterval = cfg.pollInterval;
    sessions = mapAttrsToList (_: session: {
      inherit (session) localName networkName port;
      devices = map (d: {
        inherit (d) name host port;
      }) session.devices;
    }) cfg.sessions;
  });
in
{
  options.features.midi-sessions = {
    enable = mkEnableOption "MIDI network session auto-reconnection";

    pollInterval = mkOption {
      type = types.int;
      default = 30;
      description = "Seconds between connection health checks";
    };

    sessions = mkOption {
      type = types.attrsOf sessionType;
      default = { };
      description = "MIDI network sessions to manage";
    };
  };

  config = mkIf (cfg.enable && cfg.sessions != { }) {
    user = {
      launchd.agents.midi-session-manager = {
        enable = true;
        config = {
          ProgramArguments = [
            "${pkgs.local.midi-session-manager}/bin/midi-session-manager"
            "--config"
            "${configJSON}"
          ];
          KeepAlive = true;
          RunAtLoad = true;
          StandardOutPath = "${logDir}/midi-session-manager.log";
          StandardErrorPath = "${logDir}/midi-session-manager.log";
        };
      };
    };
  };
}
