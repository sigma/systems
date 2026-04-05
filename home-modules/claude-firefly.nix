{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.claude-firefly;
  claude-code-pkg = config.programs.claude-code.finalPackage;
  urls = import ./proxy-urls.nix;
in
{
  options.programs.claude-firefly = {
    enable = mkEnableOption "Claude Code via Tailscale AI proxy";

    baseUrl = mkOption {
      type = types.str;
      default = urls.tailscaleProxy;
      description = "Anthropic API base URL (Tailscale proxy)";
    };

    timeoutMs = mkOption {
      type = types.str;
      default = "3000000";
      description = "API timeout in milliseconds";
    };

    package = mkOption {
      type = types.package;
      readOnly = true;
      description = "The claude-firefly wrapper package";
    };
  };

  config = mkIf cfg.enable {
    programs.claude-code.enable = true;

    programs.claude-firefly.package = pkgs.writeShellApplication {
      name = "claude-firefly";
      meta.description = "Claude Code via Tailscale AI proxy";
      text = ''
        export ANTHROPIC_AUTH_TOKEN="sk-tailscale"
        export ANTHROPIC_BASE_URL="${cfg.baseUrl}"
        export API_TIMEOUT_MS="${cfg.timeoutMs}"

        exec "${claude-code-pkg}/bin/claude" "$@"
      '';
    };

    home.packages = [ cfg.package ];
  };
}
