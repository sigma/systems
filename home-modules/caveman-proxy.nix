# caveman-proxy — Caveman's local LLM gateway (https://docs.caveman.so/docs/proxy),
# run as a per-user background service: launchd agent on macOS, systemd user
# unit on Linux.
#
# The binary comes from the toolbox's llm-toolchain (home-modules/default.nix
# installs the same bundle), so the service and the `caveman-proxy` on PATH are
# one pin and `caveman-proxy stats` / `status` read the same state.
#
# Defaults are upstream's: listen on 127.0.0.1:8787, record mode (byte-for-byte
# pass-through; metadata and token counts only, no request bodies on disk),
# state in ~/.caveman (caveman.yaml, caveman.db, proxy.log). Switch to
# compression with `mode: compress` in ~/.caveman/caveman.yaml.
#
# Running the service routes nothing through it: an agent opts in with
# ANTHROPIC_BASE_URL=http://127.0.0.1:8787/w/<label>. Requests through it fail
# rather than fall back if the service is down.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.caveman-proxy;

  command = "${cfg.package}/bin/caveman-proxy";

  # launchd agents get no reliable $HOME, so the state dir is always explicit.
  environment = {
    CAVEMAN_HOME = cfg.stateDir;
  };
in
{
  options.services.caveman-proxy = {
    enable = mkEnableOption "the Caveman LLM proxy as a user service";

    package = mkOption {
      type = types.package;
      default = pkgs.toolbox.llm-toolchain;
      defaultText = literalExpression "pkgs.toolbox.llm-toolchain";
      description = "Package providing {command}`bin/caveman-proxy`.";
    };

    stateDir = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.caveman";
      defaultText = literalExpression ''"''${config.home.homeDirectory}/.caveman"'';
      description = ''
        Proxy state directory ({env}`CAVEMAN_HOME`): config, SQLite stores and
        its own size-capped `proxy.log`.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf pkgs.stdenv.isDarwin {
      launchd.agents.caveman-proxy = {
        enable = true;
        config = {
          ProgramArguments = [ command ];
          EnvironmentVariables = environment;
          RunAtLoad = true;
          KeepAlive = true;
          ProcessType = "Background";
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/caveman-proxy.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/caveman-proxy.log";
        };
      };
    })

    (mkIf pkgs.stdenv.isLinux {
      systemd.user.services.caveman-proxy = {
        Unit.Description = "Caveman LLM proxy";
        Service = {
          ExecStart = command;
          Environment = mapAttrsToList (n: v: "${n}=${v}") environment;
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ "default.target" ];
      };
    })
  ]);
}
