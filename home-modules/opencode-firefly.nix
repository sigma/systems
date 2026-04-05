{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.opencode-firefly;
  urls = import ./proxy-urls.nix;
in
{
  options.programs.opencode-firefly = {
    enable = mkEnableOption "OpenCode via Tailscale AI proxy";

    baseUrl = mkOption {
      type = types.str;
      default = urls.tailscaleProxy;
      description = "OpenAI-compatible API base URL (Tailscale proxy)";
    };

    package = mkOption {
      type = types.package;
      readOnly = true;
      description = "The opencode-firefly wrapper package";
    };
  };

  config = mkIf cfg.enable {
    programs.opencode-firefly.package = pkgs.writeShellApplication {
      name = "opencode-firefly";
      meta.description = "OpenCode via Tailscale AI proxy";
      text = ''
        export OPENAI_BASE_URL="${cfg.baseUrl}"
        export OPENAI_API_KEY="sk-tailscale"

        exec opencode "$@"
      '';
    };

    home.packages = [ cfg.package ];
  };
}
