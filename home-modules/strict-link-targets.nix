# Refuse to activate over files home-manager would silently leave in place.
#
# home-manager's collision check (modules/files/check-link-targets.sh) treats
# a pre-existing file whose content happens to equal its Nix source as fine:
# it warns "will be skipped since they are the same", and linkGeneration then
# skips it too — the file stays a plain, unmanaged copy, even with
# `force = true`. That is exactly how a tool's own installer (herdr
# integration install, ...) leaves strays behind once the same file is
# declared here: the first switch after declaring it changes nothing on disk,
# and the next bump of the declared content fails activation with a "would be
# clobbered" that nothing warned about.
#
# So check first, and fail: every file in the new generation whose target
# exists and is not a symlink into a home-manager generation is an error,
# identical or not. `force = true` keeps its upstream meaning of "Nix owns
# this path" — such files are removed here so linkGeneration actually links
# them, closing the identical-content hole for forced paths as well.
#
# Walks the generation's home-files like upstream does rather than
# home.file targets, so `recursive = true` entries are checked per file (the
# directory they expand into is legitimately a real directory).
{
  config,
  lib,
  ...
}:
with lib;
let
  forcedPaths = map (f: f.target) (filter (f: f.force) (attrValues config.home.file));
in
{
  # entryBefore checkLinkTargets so the upstream skip never gets a say.
  home.activation.strictLinkTargets = hm.dag.entryBefore [ "checkLinkTargets" ] ''
    homeFilePattern="$(readlink -e ${escapeShellArg builtins.storeDir})/*-home-manager-files/*"
    newGenFiles="$(readlink -e "$newGenPath/home-files")"
    forcedPaths=(${concatMapStringsSep " " (p: ''"$HOME"/${escapeShellArg p}'') forcedPaths})
    strays=()
    while IFS= read -r -d "" sourcePath; do
      target="$HOME/''${sourcePath#"$newGenFiles"/}"
      [[ -e "$target" && ! "$(readlink "$target")" == $homeFilePattern ]] || continue
      forced=""
      for forcedPath in "''${forcedPaths[@]}"; do
        [[ $target == "$forcedPath"* ]] && forced=yes && break
      done
      if [[ -n $forced ]]; then
        [[ -L "$target" ]] && continue
        verboseEcho "Removing '$target' so the forced link replaces it"
        run rm -rf "$target"
      else
        strays+=("$target")
      fi
    done < <(find "$newGenFiles" \( -type f -or -type l \) -print0)
    if [[ ''${#strays[@]} -gt 0 ]]; then
      errorEcho "Existing files are in the way of Nix-managed ones. Remove them (or set 'force = true' on the option) and re-run:"
      for s in "''${strays[@]}"; do errorEcho "  $s"; done
      exit 1
    fi
  '';
}
