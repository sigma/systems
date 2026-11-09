# programs.quartermaster → the worklog tool and ~/.config/quartermaster/worklog.toml.
# Its MCP server is registered in claude-code.nix, its skill in agentSkills.nix.
# Projects are found by convention, not listed here (quartermaster#56).
{ machine, user, ... }:
{
  worklog = {
    # The vault lives on the macs.
    enable = machine.features.mac;
    settings.vault.repo = "~/src/github.com/${user.githubHandle}/worklog";
    # A personal routing choice, not quartermaster's default: stated in full so upstream default changes can't move it.
    settings.harness = {
      claude.kind = "claude";
      glm = {
        kind = "omp";
        args = [
          "--model"
          "zai/glm-5.3"
        ];
      };
    };
    # This checkout is off the <root>/<owner>/<repo> convention; `to=nix` sends land here.
    settings.projects."sigma/systems" = {
      path = "~/.config/nix";
      workspace = "nix";
    };
    settings.tiers = {
      default = "claude";
      basic-implementation = "glm";
      refactoring = "glm";
    };
  };
}
