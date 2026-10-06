# ~/.claude/CLAUDE.md — the global agent context, kept in this repo
# (context.md) so every host gets the same rules.
#
# Claude edits this file in live sessions when recording feedback, so on hosts
# with a checkout of this repo at ~/.config/nix (the `nix-checkout` feature) it
# is an out-of-store symlink into that checkout: edits land in the repo as an
# ordinary change, and reach other hosts on their next switch. Claude Code's
# Edit tool refuses to write through a symlink and names the target instead,
# so edits go to the repo file rather than replacing the link.
#
# Hosts without a checkout get a read-only store copy; a mkOutOfStoreSymlink
# there would dangle.
#
# Upstream's programs.claude-code.context only accepts text or a store path, so
# write the home.file entry directly, under the same absolute key it uses.
{
  config,
  lib,
  machine,
  ...
}:
let
  cfg = config.programs.claude-code;
in
{
  config = lib.mkIf cfg.enable {
    home.file."${cfg.configDir}/CLAUDE.md" = {
      source =
        if machine.features.nix-checkout then
          config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix/home-modules/claude/context.md"
        else
          ./context.md;
      # Replaces the hand-maintained copy each host had before.
      force = true;
    };
  };
}
