{ pkgs, lib, ... }:
let
  # Wrap `zed` (the real binary) and point `zeditor` at it so both invocations
  # see the same PATH. We bypass the home-manager module's `extraPackages`
  # because it wraps `zeditor` only, leaving `zed` unwrapped.
  extras = [ pkgs.direnv ];

  wrapped = pkgs.symlinkJoin {
    name = "${lib.getName pkgs.zed-editor}-wrapped-${lib.getVersion pkgs.zed-editor}";
    paths = [ pkgs.zed-editor ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/zed --suffix PATH : ${lib.makeBinPath extras}
      ln -sf zed $out/bin/zeditor
    '';
  };
in
{
  enable = true;
  package = wrapped;
}
