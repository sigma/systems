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
# state in ~/.caveman (caveman.db, proxy.log). Configuration comes from
# {option}`settings` (caveman.yaml schema), e.g. `mode = "compress"`.
#
# Running the service routes nothing through it on its own. Agents opt in per
# invocation: `claude-cave` (installed alongside claude-code) is `claude` pointed
# at the proxy, so plain `claude` keeps talking to the API directly and still
# works when the service is down — requests through the proxy fail rather than
# fall back.
#
# Tailnet upstreams. caveman's outbound SSRF guard refuses 100.64.0.0/10 and
# ULA addresses with no allowlist escape — i.e. every Tailscale address — but
# lets an explicitly allowlisted loopback port through. So
# {option}`anthropicUpstream` runs a socat relay on {option}`relayListen` to the
# tailnet host and points caveman's Anthropic provider at the relay. The relay
# dials from this machine, so the gateway still sees this node's identity.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.caveman-proxy;
  yamlFormat = pkgs.formats.yaml { };

  logDir = "${config.home.homeDirectory}/Library/Logs";

  # launchd agents get no reliable $HOME, so the state dir is always explicit.
  # The listen address is passed too, so the service and the wrapper below
  # cannot disagree on it.
  environment = {
    CAVEMAN_HOME = cfg.stateDir;
    CAVEMAN_LISTEN = cfg.listen;
  }
  // optionalAttrs (cfg.settings != { }) {
    CAVEMAN_CONFIG = toString (yamlFormat.generate "caveman.yaml" cfg.settings);
  }
  // optionalAttrs (cfg.anthropicUpstream != null) {
    CAVE_SSRF_ALLOWLIST = cfg.relayListen;
  };

  # One long-running user service, on whichever init system this host has.
  # Both keys are always present (mkIf, not `if`), so the module's shape does
  # not depend on pkgs.
  mkService =
    {
      name,
      description,
      args,
      env ? { },
    }:
    {
      launchd.agents.${name} = mkIf pkgs.stdenv.isDarwin {
        enable = true;
        config = {
          ProgramArguments = args;
          EnvironmentVariables = env;
          RunAtLoad = true;
          KeepAlive = true;
          ProcessType = "Background";
          StandardOutPath = "${logDir}/${name}.log";
          StandardErrorPath = "${logDir}/${name}.log";
        };
      };

      systemd.user.services.${name} = mkIf pkgs.stdenv.isLinux {
        Unit.Description = description;
        Service = {
          ExecStart = escapeShellArgs args;
          Environment = mapAttrsToList (n: v: "${n}=${v}") env;
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };

  relayPort = last (splitString ":" cfg.relayListen);
  relayHost = head (splitString ":" cfg.relayListen);

  # `claude` routed through the proxy. The `/w/claude` prefix labels the client
  # in `caveman-proxy stats` and is stripped before forwarding. The two extra
  # variables mirror upstream's `caveman wrap claude`: Claude Code treats any
  # non-Anthropic base URL as third-party, which caps the context window at
  # 200k and inlines every MCP tool schema; the proxy (and any tailnet gateway
  # behind it) forwards to Anthropic, so first-party behaviour is the truthful
  # one.
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
        Proxy state directory ({env}`CAVEMAN_HOME`): SQLite stores and its own
        size-capped `proxy.log`.
      '';
    };

    settings = mkOption {
      inherit (yamlFormat) type;
      default = { };
      example = {
        mode = "compress";
      };
      description = ''
        caveman.yaml contents, passed as {env}`CAVEMAN_CONFIG`. When empty,
        caveman reads {file}`caveman.yaml` from {option}`stateDir` if present.
      '';
    };

    anthropicUpstream = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "aperture:80";
      description = ''
        Plain-HTTP `host:port` of a tailnet gateway to send Anthropic traffic
        to instead of api.anthropic.com, reached through a loopback relay on
        {option}`relayListen` (see the header comment for why).
      '';
    };

    relayListen = mkOption {
      type = types.str;
      default = "127.0.0.1:8789";
      description = "Loopback `host:port` for the {option}`anthropicUpstream` relay.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf config.programs.claude-code.enable {
      home.packages = [ claude-cave ];
    })

    (mkService {
      name = "caveman-proxy";
      description = "Caveman LLM proxy";
      args = [ "${cfg.package}/bin/caveman-proxy" ];
      env = environment;
    })

    (mkIf (cfg.anthropicUpstream != null) (mkMerge [
      {
        services.caveman-proxy.settings.providers.anthropic.base_url = "http://${cfg.relayListen}";
      }
      (mkService {
        name = "caveman-relay";
        description = "Loopback relay from caveman-proxy to ${cfg.anthropicUpstream}";
        args = [
          "${pkgs.socat}/bin/socat"
          "TCP-LISTEN:${relayPort},bind=${relayHost},reuseaddr,fork"
          "TCP:${cfg.anthropicUpstream}"
        ];
      })
    ]))
  ]);
}
