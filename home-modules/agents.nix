# Agent roster: the AI coding agents a machine may carry (see CONTEXT.md).
#
# Each entry records how the agent is delivered on each platform, where it
# looks for skills, and how other tools integrate with it. Everything that
# installs an agent, links skills into it, or wires it into another tool reads
# the roster instead of re-deriving which agents this machine has:
#
#   - this module installs Linux packages and drives programs.claude-code
#   - darwin-modules/apps/agents.nix installs the Homebrew formulae/casks
#   - settings/programs/agentSkills.nix links skills into every skillDir
#   - programs/herdr.nix integrates every herdrId
#   - settings/programs/zed-editor.nix registers every acp id
#
# Delivery channels differ per platform on purpose. On darwin, Homebrew tracks
# these fast-moving agents more closely than nixpkgs; on Linux there is no
# Homebrew, so the equivalent move is pkgs.master (the pinned unstable channel
# lags by several releases). An entry with no channel for the current platform
# is never installed, whatever its enable says.
#
# Gates: `floor` is the base-floor agent, on everywhere (devboxes included);
# `ai` follows the resolved `ai` content feature, so the devbox policy turns it
# off; `off` waits for a policy to enable it.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.agents;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  gateDefault = {
    floor = true;
    ai = config.features.ai.enable;
    off = false;
  };

  # An endpoint variant (see CONTEXT.md): the agent re-pointed at another API
  # endpoint, delivered as a `<agent-binary>-<name>` wrapper.
  endpointType = types.submodule {
    options = {
      description = mkOption {
        type = types.str;
        description = "One-line description of the wrapper.";
      };
      baseUrl = mkOption {
        type = types.str;
        description = "API base URL (ANTHROPIC_BASE_URL).";
      };
      firstParty = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether the endpoint forwards to Anthropic. Claude Code treats any
          non-Anthropic base URL as third-party, which caps the context window
          at 200k and inlines every MCP tool schema; set this when first-party
          behaviour is the truthful one.
        '';
      };
      tokenFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "File holding the API token (ANTHROPIC_AUTH_TOKEN), read at launch.";
      };
      timeoutMs = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        description = "API timeout in milliseconds (API_TIMEOUT_MS).";
      };
      env = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Extra variables to export; values are double-quoted shell words, expanded at launch.";
      };
      acp = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Agent Client Protocol registry id, for editors that host external agents (Zed).";
      };
    };
  };

  mkClaudeEndpoint =
    name: e:
    pkgs.writeShellApplication {
      name = "claude-${name}";
      meta.description = e.description;
      text = concatLines (
        optional (e.tokenFile != null) ''
          if [[ ! -f "${e.tokenFile}" ]]; then
            echo "API token not found at: ${e.tokenFile}" >&2
            echo "Run system-install first to decrypt secrets" >&2
            exit 1
          fi
          export ANTHROPIC_AUTH_TOKEN
          ANTHROPIC_AUTH_TOKEN=$(cat "${e.tokenFile}")''
        ++ [ ''export ANTHROPIC_BASE_URL="${e.baseUrl}"'' ]
        ++ optional e.firstParty "export _CLAUDE_CODE_ASSUME_FIRST_PARTY_BASE_URL=1"
        ++ optional (e.timeoutMs != null) ''export API_TIMEOUT_MS="${toString e.timeoutMs}"''
        ++ mapAttrsToList (n: v: ''export ${n}="${v}"'') e.env
        ++ [ ''exec "${config.programs.claude-code.finalPackage}/bin/claude" "$@"'' ]
      );
    };

  entryType = types.submodule (
    { config, ... }:
    {
      options = {
        gate = mkOption {
          type = types.enum [
            "floor"
            "ai"
            "off"
          ];
          description = "Default gate deciding whether the agent is enabled.";
        };

        enable = mkOption {
          type = types.bool;
          default = gateDefault.${config.gate};
          defaultText = literalExpression "derived from gate";
          description = "Whether the machine carries this agent. Policies may override the gate.";
        };

        darwin = {
          brew = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Homebrew formula delivering the agent on darwin.";
          };
          cask = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Homebrew cask delivering the agent on darwin.";
          };
        };

        linux.package = mkOption {
          type = types.nullOr types.package;
          default = null;
          description = "Package delivering the agent on Linux.";
        };

        skillDir = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Home-relative directory the agent scans for skills.";
        };

        acp = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Agent Client Protocol registry id, for editors that host external agents (Zed).";
        };

        endpoints = mkOption {
          type = types.attrsOf endpointType;
          default = { };
          description = "Endpoint variants of this agent. Only claude-code supports them today.";
        };

        herdrId = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "herdr integration id (`herdr integration install <id>`).";
        };

        installed = mkOption {
          type = types.bool;
          readOnly = true;
          default =
            config.enable
            && (
              if isDarwin then
                config.darwin.brew != null || config.darwin.cask != null
              else
                config.linux.package != null
            );
          description = "Whether the agent is enabled and has a delivery channel on this platform.";
        };
      };
    }
  );

  installed = filterAttrs (_: a: a.installed) cfg;
in
{
  options.programs.agents = mkOption {
    type = types.attrsOf entryType;
    default = { };
    description = "The agent roster.";
  };

  config = {
    programs.agents = {
      claude-code = {
        gate = "floor";
        # `@latest` tracks the rolling release channel; the plain cask pins.
        darwin.cask = "claude-code@latest";
        linux.package = pkgs.master.claude-code;
        skillDir = ".claude/skills";
        acp = "claude-acp";
        herdrId = "claude";
      };

      pi = {
        gate = "ai";
        darwin.brew = "pi-coding-agent";
        linux.package = pkgs.master.pi-coding-agent;
        skillDir = ".pi/agent/skills";
        herdrId = "pi";
      };

      opencode = {
        gate = "ai";
        linux.package = pkgs.master.opencode;
        # No skillDir: opencode already scans ~/.claude/skills (the floor
        # agent's), so linking the set into its own directory would list every
        # skill twice. https://opencode.ai/docs/skills/
        herdrId = "opencode";
      };

      gemini-cli = {
        gate = "ai";
        darwin.brew = "gemini-cli";
        skillDir = ".gemini/skills";
        acp = "gemini";
      };

      # Work-only; enabled by policy (darwin-modules/policy/firefly.nix).
      antigravity-cli = {
        gate = "off";
        darwin.cask = "antigravity-cli";
        # Global location per https://antigravity.google/docs/skills/; the
        # per-project <workspace>/.agents/skills is deliberately left alone.
        skillDir = ".gemini/config/skills";
      };
    };

    # claude-code is the one agent with a home-manager module, which installs
    # it (and its settings) itself; darwin swaps in a Homebrew wrapper package.
    programs.claude-code = {
      inherit (cfg.claude-code) enable;
      package = mkIf (cfg.claude-code.linux.package != null) (mkDefault cfg.claude-code.linux.package);
    };

    home.packages =
      optionals (!isDarwin) (
        mapAttrsToList (_: a: a.linux.package) (removeAttrs installed [ "claude-code" ])
      )
      ++ optionals cfg.claude-code.enable (mapAttrsToList mkClaudeEndpoint cfg.claude-code.endpoints);

    assertions = mapAttrsToList (n: a: {
      assertion = n == "claude-code" || a.endpoints == { };
      message = "programs.agents.${n}.endpoints: endpoint variants are only implemented for claude-code.";
    }) cfg;

    # agy's status-line HUD comes with agy itself.
    programs.agy-hud.enable = mkDefault (installed ? antigravity-cli);
  };
}
