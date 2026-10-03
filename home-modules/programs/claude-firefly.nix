# claude-firefly: Claude Code through the tailnet's Aperture gateway, an
# endpoint variant of the claude-code roster entry (see ../agents.nix).
{
  config,
  lib,
  machine,
  ...
}:
let
  urls = import ../proxy-urls.nix machine.sharedDomain;
in
{
  options.programs.claude-firefly.enable = lib.mkEnableOption "Claude Code via the Tailscale AI proxy";

  config = lib.mkIf config.programs.claude-firefly.enable {
    programs.agents.claude-code.endpoints.firefly = {
      description = "Claude Code via Tailscale AI proxy";
      baseUrl = urls.tailscaleProxy;
      # Aperture forwards to Anthropic.
      firstParty = true;
      timeoutMs = 3000000;
    };
  };
}
