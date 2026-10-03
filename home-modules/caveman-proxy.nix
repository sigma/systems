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
# Running the service routes nothing through it on its own. Agents opt in per
# invocation: `claude-cave` (installed alongside claude-code) is `claude` pointed
# at the proxy, so plain `claude` keeps talking to the API directly and still
# works when the service is down — requests through the proxy fail rather than
# fall back.
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
  # The listen address is passed too, so the service and the wrapper below
  # cannot disagree on it.
  environment = {
    CAVEMAN_HOME = cfg.stateDir;
    CAVEMAN_LISTEN = cfg.listen;
  };

  # `claude` routed through the proxy. The `/w/claude` prefix labels the client
  # in `caveman-proxy stats` and is stripped before forwarding. The two extra
  # variables mirror upstream's `caveman wrap claude`: Claude Code treats any
  # non-Anthropic base URL as third-party, which caps the context window at
  # 200k and inlines every MCP tool schema; the proxy forwards to
  # api.anthropic.com unchanged, so first-party behaviour is the truthful one.
  claude-cave = pkgs.writeShellApplication {
    name = "claude-cave";
    meta.description = "Claude Code routed through the local caveman-proxy";
    text = ''
      export ANTHROPIC_BASE_URL="http://${cfg.listen}/w/claude"
      export _CLAUDE_CODE_ASSUME_FIRST_PARTY_BASE_URL=1
      export ENABLE_TOOL_SEARCH=auto
      export NO_PROXY="${listenHost}''${NO_PROXY:+,$NO_PROXY}"
      export no_proxy="$NO_PROXY"

      exec "${config.programs.claude-code.finalPackage}/bin/claude" "$@"
    '';
  };

  listenHost = head (splitString ":" cfg.listen);
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

    listen = mkOption {
      type = types.str;
      default = "127.0.0.1:8787";
      description = ''
        Loopback `host:port` the proxy listens on ({env}`CAVEMAN_LISTEN`) and
        `claude-cave` connects to. A non-loopback address additionally needs
        {env}`CAVEMAN_AUTH_TOKEN`, which this module does not provision.
      '';
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
    (mkIf config.programs.claude-code.enable {
      home.packages = [ claude-cave ];
    })

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
