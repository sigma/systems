# Fix chmod failure in make-disk-image when building in Determinate Nix's external builder
# The external builder doesn't allow changing permissions on /build
# This patches vmTools.runInLinuxVM to handle chmod failures gracefully
final: prev:
let
  inherit (prev) lib;
  patchPreVM = script:
    if script == null || script == "" then
      script
    else
      builtins.replaceStrings
        [ ''chmod 755 "$TMPDIR"'' ]
        [ ''chmod 755 "$TMPDIR" 2>/dev/null || true'' ]
        script;
in
{
  vmTools = prev.vmTools // {
    runInLinuxVM =
      drv:
      let
        result = prev.vmTools.runInLinuxVM drv;
      in
      lib.overrideDerivation result (old: {
        preVM = patchPreVM (old.preVM or "");
      });
  };
}
