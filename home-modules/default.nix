{
  lib,
  machine,
  stateVersion,
  ...
}:
{
  home.stateVersion = stateVersion;

  imports = [
    # Tool modules (one per tool, self-gating), auto-discovered.
    ./programs
    # Values for tools configured purely through upstream home-manager modules.
    ./settings
    # Content-feature package lists, one file per feature (plus the base floor).
    ./content

    # Infrastructure: options other modules read, and cross-cutting wiring.
    ./accounts.nix
    ./agent-env.nix # interactive-editor lockout shared by every coding agent
    ./agent-skills.nix # skill registry linked into every agent's skill root
    ./agents.nix # agent roster: skills, herdr and installs derive from it
    ./ai-apis.nix # local LLM endpoints by protocol (set by the server module)
    ./builder-access.nix
    ./catppuccin.nix
    # Nests ~/.claude/settings.json inside a store *directory* so Claude does
    # not end up watching /nix/store itself.
    ./claude-settings-file.nix
    ./claude # ~/.claude/CLAUDE.md, live-editable on nix-checkout hosts
    ./claude-statusline.nix # composable statusline (voice.nix adds a segment)
    ./commit-signing.nix # signing key + allowed-signers shared by git and jj
    ./editors
    ./features.nix # declares options.features.<n>.enable (content-feature seam)
    ./fonts
    ./mailsetup.nix
    ./policy # gates internally on machine.features.<x>
    ./shells
    # Fails activation on unmanaged files at home.file targets instead of
    # letting home-manager skip identical ones silently.
    ./strict-link-targets.nix
  ]
  ++ lib.optionals machine.features.mac [
    ./darwin-apps.nix # references darwin apps; mac is structural (import-time)
  ];
}
