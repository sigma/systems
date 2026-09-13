# AI agent CLIs on NixOS.
#
# The Linux counterpart to darwin-modules/apps/ai.nix, which reaches for
# Homebrew because those formulae track upstream more closely than nixpkgs.
# There is no Homebrew here, so the equivalent move is pkgs.master: these
# agents ship several releases a week and the pinned unstable channel lags
# noticeably (opencode 1.15 vs 1.18, pi 0.75 vs 0.83 at time of writing).
# Same reasoning already applied to claude-code in ./dev.nix.
{ pkgs, ... }:
{
  user.home.packages = with pkgs.master; [
    opencode # terminal coding agent (opencode.ai)
    pi-coding-agent # pi AI agent toolkit (pi.dev)
  ];
}
