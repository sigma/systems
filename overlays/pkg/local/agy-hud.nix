# agy-hud — compact status-line HUD plugin for Google's Antigravity CLI (`agy`).
#
# Upstream ships this as an Antigravity *plugin archive*, not an npm package:
# a plugin root holding `plugin.json`, `hooks/status-line.sh` and the esbuild
# bundle `dist/agy-hud.js`. We reproduce that shape under $out/share/agy-hud so
# the plugin root can be symlinked straight into ~/.gemini/config/plugins (see
# darwin-modules/apps/antigravity-cli.nix) instead of being copied in with
# `agy plugin install`.
#
# Two deviations from the archive, both so the plugin works without a global
# node on PATH:
#   - hooks/status-line.sh is replaced with one that execs an absolute nodejs.
#   - $out/bin/agy-hud is added for the documented `version` / `quota refresh`
#     subcommands, which the archive leaves to a bare `node <root>/dist/...`.
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  makeWrapper,
  nodejs,
}:

buildNpmPackage rec {
  pname = "agy-hud";
  version = "0.1.9";

  src = fetchFromGitHub {
    owner = "franksde";
    repo = "agy-hud";
    rev = "v${version}";
    hash = "sha256-NwW/0s1B9KqsE9BlfGu69S3YDzj0bgcN87OCvRnEZiE=";
  };

  npmDepsHash = "sha256-cbc+X1K27v4lq0uLVgOtf5sfZtDMmms6ZjZG7rNfqz4=";

  nativeBuildInputs = [ makeWrapper ];

  # `npm run build` bundles src/main.ts into dist/agy-hud.js with esbuild.
  # Runtime deps are bundled, so node_modules is not installed.

  installPhase = ''
    runHook preInstall

    root=$out/share/agy-hud
    mkdir -p $root/dist $root/hooks $out/bin

    cp dist/agy-hud.js $root/dist/
    cp plugin.json config.example.json LICENSE $root/

    # Upstream's hook resolves the plugin root from $0 and execs a bare `node`;
    # ours pins the interpreter so the HUD does not need a node on PATH.
    echo "#!/bin/sh" > $root/hooks/status-line.sh
    echo "exec ${nodejs}/bin/node $root/dist/agy-hud.js statusline" >> $root/hooks/status-line.sh
    chmod +x $root/hooks/status-line.sh

    makeWrapper ${nodejs}/bin/node $out/bin/agy-hud \
      --add-flags $root/dist/agy-hud.js

    runHook postInstall
  '';

  meta = with lib; {
    description = "Compact status-line HUD plugin for the Antigravity CLI";
    homepage = "https://github.com/franksde/agy-hud";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.unix;
    mainProgram = "agy-hud";
  };
}
