# AI agent CLIs installed via Homebrew.
#
# Terminal AI coding agents whose Homebrew formulae track upstream more
# closely than nixpkgs. Grouped here rather than scattered through the generic
# apps brew list, next to the other AI app modules (claude-code, gemini-cli).
{ ... }:
{
  homebrew.brews = [
    "herdr" # terminal agent multiplexer (herdr.dev)
    "pi-coding-agent" # pi AI agent toolkit (pi.dev)
  ];
}
