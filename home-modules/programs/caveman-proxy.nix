# caveman-proxy — Caveman's local LLM gateway (https://docs.caveman.so/docs/proxy),
# run as a per-user background service: launchd agent on macOS, systemd user
# unit on Linux.
#
# The binary comes from the toolbox's llm-toolchain (home-modules/content/dev.nix
# installs the same bundle), so the service and the `caveman-proxy` on PATH are
# one pin and `caveman-proxy stats` / `status` read the same state.
#
# Listens on 127.0.0.1:8787 with state in ~/.caveman (caveman.db, proxy.log),
# upstream's defaults. Configuration comes from {option}`settings` (caveman.yaml
# schema).
#
# Compress mode. {option}`settings` defaults `mode` to "compress" (upstream's
# default is "record": byte-for-byte pass-through, metadata only). The proxy
# shortens fresh tool results, lossily, and keeps each original in
# ~/.caveman/ccr.db under a ccr_… handle; it only does so when the model can
# fetch originals back through the `caveman_retrieve` MCP tool. `claude-cave`
# therefore registers caveman-mcp (same llm-toolchain bundle, so the proxy and
# the MCP server share one pin and one ccr.db format) as the `caveman` server.
# ENABLE_TOOL_SEARCH defers MCP tool schemas, so the request does not always
# list that tool; CAVEMAN_RECOVERY=mcp asserts it out of band instead. That
# assertion holds only while every client of the proxy registers caveman-mcp,
# which today means `claude-cave` alone. Record mode drops both.
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
# {option}`anthropicUpstream` runs a socat relay on
# {option}`relayHost`:{option}`relayPort` to the tailnet host and points
# caveman's Anthropic provider at the relay. The relay dials from this machine,
# so the gateway still sees this node's identity.
{
  config,
  lib,
  machine,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.caveman-proxy;
  yamlFormat = pkgs.formats.yaml { };

  logDir = "${config.home.homeDirectory}/Library/Logs";

  # `host:port`, bracketing IPv6 literals.
  hostPort =
    host: port: if hasInfix ":" host then "[${host}]:${toString port}" else "${host}:${toString port}";

  listen = hostPort cfg.listenHost cfg.listenPort;

  compress = cfg.settings.mode or "record" == "compress";

  # The recovery server must open the proxy's ccr.db, so it gets the same
  # CAVEMAN_HOME.
  mcpConfig = pkgs.writeText "caveman-mcp.json" (
    builtins.toJSON {
      mcpServers.caveman = {
        command = "${cfg.package}/bin/caveman-mcp";
        env.CAVEMAN_HOME = cfg.stateDir;
      };
    }
  );
  relay = hostPort cfg.relayHost cfg.relayPort;

  # socat needs TCP6 and a bracketed bind address for an IPv6 relay host.
  relayIsV6 = hasInfix ":" cfg.relayHost;
  relayProto = if relayIsV6 then "TCP6" else "TCP";
  relayBind = if relayIsV6 then "[${cfg.relayHost}]" else cfg.relayHost;

  # Neither port is authenticated, so both stay on loopback.
  loopbackHost =
    types.addCheck types.str (h: h == "localhost" || h == "::1" || hasPrefix "127." h)
    // {
      description = "loopback host (localhost, ::1 or 127.0.0.0/8)";
    };

  # launchd agents get no reliable $HOME, so the state dir is always explicit.
  # The listen address is passed too, so the service and the wrapper below
  # cannot disagree on it.
  environment = {
    CAVEMAN_HOME = cfg.stateDir;
    CAVEMAN_LISTEN = listen;
  }
  // optionalAttrs (cfg.settings != { }) {
    CAVEMAN_CONFIG = toString (yamlFormat.generate "caveman.yaml" cfg.settings);
  }
  // optionalAttrs (cfg.anthropicUpstream != null) {
    CAVE_SSRF_ALLOWLIST = relay;
  }
  // optionalAttrs compress {
    CAVEMAN_RECOVERY = "mcp";
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

in
{
  options.services.caveman-proxy = {
    enable = mkEnableOption "the Caveman LLM proxy as a user service" // {
      default = config.features.dev.enable;
      defaultText = literalExpression "config.features.dev.enable";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.toolbox.llm-toolchain;
      defaultText = literalExpression "pkgs.toolbox.llm-toolchain";
      description = "Package providing {command}`bin/caveman-proxy` and {command}`bin/caveman-mcp`.";
    };

    listenHost = mkOption {
      type = loopbackHost;
      default = "127.0.0.1";
      description = ''
        Loopback host the proxy listens on ({env}`CAVEMAN_LISTEN`) and
        `claude-cave` connects to. Restricted to loopback: a reachable proxy
        needs {env}`CAVEMAN_AUTH_TOKEN`, which this module does not provision.
      '';
    };

    listenPort = mkOption {
      type = types.port;
      default = 8787;
      description = "Port the proxy listens on.";
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
        mode = "record";
      };
      description = ''
        caveman.yaml contents, passed as {env}`CAVEMAN_CONFIG`. `mode`
        defaults to "compress" (see the header comment), so this is never
        empty and {file}`caveman.yaml` in {option}`stateDir` is not read:
        put its contents here instead.
      '';
    };

    anthropicUpstream = mkOption {
      type = types.nullOr types.str;
      # Tailnet hosts send Anthropic traffic through the Aperture gateway.
      default =
        if machine.features.tailscale then
          (import ../proxy-urls.nix machine.sharedDomain).aperture
        else
          null;
      defaultText = literalExpression "Aperture on tailnet hosts, else null";
      example = "aperture:80";
      description = ''
        Plain-HTTP `host:port` of a tailnet gateway to send Anthropic traffic
        to instead of api.anthropic.com, reached through a loopback relay on
        {option}`relayHost`:{option}`relayPort` (see the header comment for
        why). Sets {option}`settings`.providers.anthropic.base_url.
      '';
    };

    relayHost = mkOption {
      type = loopbackHost;
      default = "127.0.0.1";
      description = "Loopback host for the {option}`anthropicUpstream` relay.";
    };

    relayPort = mkOption {
      type = types.port;
      default = 8789;
      description = "Port for the {option}`anthropicUpstream` relay.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.caveman-proxy.settings.mode = mkDefault "compress";

      # `claude` routed through the proxy (an endpoint variant, see
      # ../agents.nix). The `/w/claude` prefix labels the client in
      # `caveman-proxy stats` and is stripped before forwarding. The proxy
      # (and any tailnet gateway behind it) forwards to Anthropic, so
      # first-party behaviour is the truthful one; ENABLE_TOOL_SEARCH mirrors
      # upstream's `caveman wrap claude`.
      programs.agents.claude-code.endpoints.cave = {
        description = "Claude Code routed through the local caveman-proxy";
        baseUrl = "http://${listen}/w/claude";
        firstParty = true;
        env = {
          ENABLE_TOOL_SEARCH = "auto";
          NO_PROXY = "${cfg.listenHost}\${NO_PROXY:+,$NO_PROXY}";
          no_proxy = "$NO_PROXY";
        };
        # `=` form: --mcp-config takes several values and would swallow a
        # positional prompt.
        args = optional compress "--mcp-config=${mcpConfig}";
      };
    }

    (mkService {
      name = "caveman-proxy";
      description = "Caveman LLM proxy";
      args = [ "${cfg.package}/bin/caveman-proxy" ];
      env = environment;
    })

    (mkIf (cfg.anthropicUpstream != null) (mkMerge [
      {
        services.caveman-proxy.settings.providers.anthropic.base_url = "http://${relay}";
      }
      (mkService {
        name = "caveman-relay";
        description = "Loopback relay from caveman-proxy to ${cfg.anthropicUpstream}";
        args = [
          "${pkgs.socat}/bin/socat"
          "${relayProto}-LISTEN:${toString cfg.relayPort},bind=${relayBind},reuseaddr,fork"
          "TCP:${cfg.anthropicUpstream}"
        ];
      })
    ]))
  ]);
}
