# programs.quartermaster → the worklog tool and ~/.config/quartermaster/worklog.toml.
# Its MCP server is registered in claude-code.nix, its skill in agentSkills.nix.
# Projects are found by convention, not listed here (quartermaster#56).
{ machine, user, ... }:
{
  worklog = {
    # The vault lives on the macs.
    enable = machine.features.mac;
    settings.vault.repo = "~/src/github.com/${user.githubHandle}/worklog";
  };
}
