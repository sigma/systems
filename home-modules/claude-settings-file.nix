# ~/.claude/settings.json must not be a *bare* store path.
#
# Claude Code resolves a symlinked settings file and *also* watches the
# directory containing the resolved target, so that atomic-save edits (write to
# temp + rename) are noticed. Its own debug output says so:
#
#   <path> is a symlink to <target>; also watching <dir> so atomic-save edits
#   to the target are detected
#
# The intent is fine; the absence of any bound on that directory's size is not.
# home-manager's `jsonFormat.generate` yields a top-level store path, so the
# watched directory is /nix/store itself — 366,845 entries here. Every store
# write then triggers a full enumeration.
#
# Measured 2026-08-15 with sample(1) + fs_usage(1) on an *idle* session during
# `nh darwin build .`: 741,519 lstat on store entries per 45s (~2 full passes),
# 16 openat on the store root, 300-500% CPU — which also starves the build that
# triggered it. Nesting the file one level down takes /nix/store syscalls from
# 215,483 in a 20s window to 0.
#
# ---------------------------------------------------------------------------
# DELETE THIS FILE once the home-manager input contains
# 56ccab89189f63dcd14a3f5710c8d3577d81f22a (PR nix-community/home-manager#9689,
# "programs.claude-code: avoid watching the Nix store", merged 2026-07-20).
# That commit does exactly this upstream, so keeping ours would only shadow it.
#
# Our pin (flake.lock: d4fd2466) is 279 commits behind that merge, hence this
# stopgap. Check with:
#   gh api repos/nix-community/home-manager/compare/56ccab89...<our-rev> \
#     --jq .status     # "diverged"/"behind" => still needed
# ---------------------------------------------------------------------------
#
# Because we re-render the file, we must reproduce every key upstream folds in,
# or they vanish silently. At our pinned rev that is `$schema` and
# `extraKnownMarketplaces`. Newer home-manager also derives
# `disabledMcpjsonServers` from internal state we cannot reach from here — a
# further reason to delete this file on the next bump rather than extend it.
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  cfg = config.programs.claude-code;

  # Tripwire: detect the upstream fix directly rather than by proxy, and fail
  # the build when it lands so this file cannot quietly outlive its purpose.
  #
  # We read home-manager's own claude-code module (modulesPath points at its
  # modules/ tree) and look for the derivation name #9689 introduced. Upstream
  # moved the module from a flat file to a directory at some point, so try both.
  #
  # Failure mode is deliberately the safe one: if upstream ever *renames* that
  # derivation, this goes quiet and we keep a redundant-but-harmless override,
  # rather than silently dropping settings keys.
  upstreamModule =
    let
      candidates = [
        "${modulesPath}/programs/claude-code/default.nix"
        "${modulesPath}/programs/claude-code.nix"
      ];
    in
    lib.findFirst builtins.pathExists null candidates;

  upstreamNestsSettings =
    upstreamModule != null
    && lib.hasInfix "claude-code-settings-directory" (builtins.readFile upstreamModule);

  # Same generator upstream uses, so the rendered JSON stays byte-identical.
  jsonFormat = pkgs.formats.json { };

  # Mirrors home-manager's internal mkMarketplaceEntry (modules/programs/
  # claude-code.nix:588 at the pinned rev); it is not exported, so we inline it.
  mkMarketplaceEntry = _name: content: {
    source = {
      source = "directory";
      path = content;
    };
  };

  # `or` guards keep this evaluating if a bump renames or drops the option
  # before we get around to deleting the file.
  marketplaces = cfg.marketplaces or { };

  settingsFile = jsonFormat.generate "claude-code-settings.json" (
    cfg.settings
    // {
      "$schema" = "https://json.schemastore.org/claude-code-settings.json";
    }
    // lib.optionalAttrs (marketplaces != { }) {
      extraKnownMarketplaces = lib.mapAttrs mkMarketplaceEntry marketplaces;
    }
  );

  # install(1) rather than a symlink: realpath resolves through symlinks back to
  # the bare store file, which would defeat the whole exercise. Matches what
  # #9689 does upstream.
  settingsDir = pkgs.runCommandLocal "claude-code-settings-directory" { } ''
    install -Dm444 ${settingsFile} "$out/settings.json"
  '';
in
{
  # Match upstream's own gate, or our mkForce would *create* the entry on a
  # host where upstream writes no settings file at all.
  config = lib.mkIf (cfg.enable && (cfg.settings != { } || marketplaces != { })) {
    assertions = [
      {
        assertion = !upstreamNestsSettings;
        message = ''
          home-modules/claude-settings-file.nix is obsolete: home-manager now
          nests ~/.claude/settings.json in its own store directory itself
          (PR nix-community/home-manager#9689).

          Delete home-modules/claude-settings-file.nix and drop its import from
          home-modules/default.nix. Keeping it would shadow upstream and, worse,
          silently drop any settings keys upstream folds in that this file does
          not reproduce (e.g. disabledMcpjsonServers).
        '';
      }
    ];

    # Upstream registers this entry under the *absolute* path, so match that key
    # exactly or we would add a second, conflicting entry.
    home.file."${config.home.homeDirectory}/.claude/settings.json".source =
      lib.mkForce "${settingsDir}/settings.json";
  };
}
