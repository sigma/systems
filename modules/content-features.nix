# Content-feature registry.
#
# The canonical list of content features — feature axes that select home-manager
# content and nothing else (see CONTEXT.md). Everything that generates, gates on,
# or enforces content features derives from this one list:
#   - home-modules/features.nix declares options.features.<n>.enable from it
#   - modules/nebula/helpers.nix generates the per-host mkDefault module from it
#   - home-modules/policy/devbox.nix forces its complement off on devboxes
#
# Structural features (mac, nixos, laptop, devbox, tailscale, llm, ...) are NOT
# listed here: they are read before config exists or outside home scope, so they
# stay plain host-declared data in machine.features.*.
[
  "dev" # software development toolchain (languages, build, git, nix tooling)
  "shell" # interactive shell power-user toolkit (console tools, json/yaml)
  "ai" # multi-provider AI agent stack (beyond the base single agent)
  "writing" # authoring tools (hugo, mdbook)
  "media" # media tooling (ffmpeg, yt-dlp, kew)
  "network" # network tools (nmap, lftp, autossh)
  "keyboard" # keyboard firmware tooling (QMK)
  "graphical" # fonts + GUI apps (terminal, GUI editor); off on headless devboxes
  "music" # music production
  "gaming" # gaming
]
