# tuicr's Herdr wrapper builds a bash-syntax completion sentinel and hands it to
# `herdr pane run`, which injects it into the pane's *interactive* shell. That
# shell is fish here, and fish has neither `$?` nor `VAR=value` assignment, so
# the wrapper dies before tuicr ever starts. The patch wraps the payload in
# `bash -c '...'` so the pane's shell only forwards one single-quoted argument.
#
# Local until https://github.com/agavra/tuicr upstreams the fix; drop this file
# once the toolbox input carries a tuicr release that includes it.
#
# tuicr-skills is a `buildCommand` derivation (no unpack/patch phases), so
# overrideAttrs has nothing to hook -- patch a copy of its output instead.
final: prev: {
  toolbox = prev.toolbox // {
    tuicr-skills = final.runCommand "${prev.toolbox.tuicr-skills.name}-herdr-fish" { } ''
      cp -R ${prev.toolbox.tuicr-skills} $out
      chmod -R u+w $out
      patch -p1 -d $out < ${./tuicr-skills-herdr-fish.patch}
    '';
  };
}
