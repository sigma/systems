# herdr agent integrations, generated in a build sandbox instead of installed
# imperatively.
#
# `herdr integration install <target>` drops a small state-reporting script into
# the agent's own extension/hook directory, so the agent reports its state to
# herdr directly instead of herdr guessing from process detection. Run by hand,
# that leaves unmanaged files in $HOME which nothing keeps in step with the herdr
# package: bump herdr and the scripts stay at whatever version last installed
# them.
#
# Two observations make a declarative version possible:
#
#   1. The payloads are embedded in the binary, so the installer needs no
#      network and runs in a build sandbox.
#   2. The scripts contain no absolute paths, so they are content-addressable —
#      a store path serves them as well as a $HOME copy. (Verified: the files
#      this derivation produces are byte-identical to what the imperative
#      installer writes.)
#
# So we run the installer against a throwaway HOME at build time, capture the
# artifacts, and link them in with home.file. The result tracks the herdr
# package automatically: a new herdr means a new derivation, which means new
# symlinks on the next activation.
#
# Claude is the exception and the reason this module exists at all. Its
# integration is two parts — the hook script, plus a SessionStart registration
# in ~/.claude/settings.json — and that file is a read-only store path here
# (see ./claude-settings-file.nix). `herdr integration install claude` writes
# the script, then dies with "Read-only file system (os error 30)" before
# registering, leaving a hook that Claude never invokes. `herdr integration
# status` still calls it "current", because it only stats the script. So the
# registration is declared below in Nix, which is the only writer of that file.
#
# Because that registration is hand-written, the derivation doubles as a drift
# guard: it diffs what herdr *wants* registered against what we declare, and
# fails the build if the shape ever changes.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.herdr;

  # Every file each target writes, relative to $HOME. Installing an integration
  # is not always a single file drop: opencode also gets a TUI-session plugin
  # and a tui.jsonc registering it (by relative path, so a symlink is fine).
  #
  # These are listed here rather than read back out of the derivation because
  # home.file keys must be known at eval time, and reading them would mean
  # import-from-derivation. Nothing is assumed, though — the completeness guard
  # in the derivation below fails the build if herdr writes a file that is not
  # listed here, which is how the opencode extras were caught in the first
  # place.
  knownTargets = {
    claude = [ ".claude/hooks/herdr-agent-state.sh" ];
    opencode = [
      ".config/opencode/plugins/herdr-agent-state.js"
      ".config/opencode/herdr-tui-session.js"
      # Since herdr 0.9.1 the TUI plugin is also exposed in opencode's "v2"
      # directory form: cli.json points at the herdr-opencode/ directory, whose
      # tui.js is a one-line re-export of ../herdr-tui-session.js. The relative
      # import survives the store: the two files keep the same layout under
      # $out/files as they do under $HOME, so it resolves either side of the
      # symlink.
      ".config/opencode/herdr-opencode/tui.js"
      # Owned outright, not merged: herdr "ensures" these files, so a hand-added
      # plugin entry here would be lost on rebuild. They hold only herdr's own
      # `{"plugin": ["./herdr-tui-session.js"]}` and
      # `{"plugins": ["./herdr-opencode"]}` today.
      ".config/opencode/tui.jsonc"
      ".config/opencode/cli.json"
    ];
    pi = [ ".pi/agent/extensions/herdr-agent-state.ts" ];
    omp = [ ".omp/agent/extensions/herdr-omp-agent-state.ts" ];
  };

  # Claude's registration is translated into Nix (see header) instead of being
  # copied, so it is the one file the completeness guard must forgive.
  translatedFiles = [ ".claude/settings.json" ];

  selected = cfg.integrations;
  selectedFiles = concatMap (t: knownTargets.${t}) selected;
  wantsClaude = elem "claude" selected;

  # Generate with the herdr we install, so the integration version always
  # matches the binary that consumes it.
  generator = cfg.package;

  # The SessionStart registration herdr asks for. Parameterised by command
  # because the drift check and the real setting disagree on exactly that
  # field, and because referring to `integrations` from the value the
  # derivation checks would be a cycle.
  mkClaudeRegistration = command: {
    SessionStart = [
      {
        matcher = "^(startup|resume|clear|compact|fork)$";
        hooks = [
          {
            type = "command";
            inherit command;
            timeout = 10;
          }
        ];
      }
    ];
  };

  # herdr registers a command pointing into $HOME; we point at the store, the
  # way the WorktreeCreate/WorktreeRemove hooks already do. That one field is
  # deliberately ours, so blank it on both sides before diffing — everything
  # else (event name, matcher, type, timeout, number of entries) must match
  # herdr exactly.
  normalise =
    file:
    "${getExe pkgs.jq} -S '.hooks | walk("
    + "if type == \"object\" and has(\"command\") then .command = \"@CMD@\" else . end)' "
    + file;

  declaredRegistration = (pkgs.formats.json { }).generate "claude-registration.json" {
    hooks = mkClaudeRegistration "@DECLARED@";
  };

  integrations =
    pkgs.runCommandLocal "herdr-integrations-${generator.version}"
      {
        nativeBuildInputs = [ pkgs.findutils ];
      }
      ''
        export HOME="$NIX_BUILD_TOP/fakehome"

        # herdr refuses to install unless the agent's directory already exists
        # ("install <agent> first"). That guard is a proxy for "is the agent
        # present", which Nix has already answered by putting it in this profile —
        # and pi never creates its own extensions directory, so the guard would
        # otherwise be unsatisfiable.
        ${concatMapStringsSep "\n" (p: ''mkdir -p "$HOME/$(dirname ${escapeShellArg p})"'') selectedFiles}
        ${optionalString wantsClaude ''printf '{}' > "$HOME/.claude/settings.json"''}

        ${concatMapStringsSep "\n" (t: ''
          echo "installing ${t} integration"
          ${getExe' generator "herdr"} integration install ${escapeShellArg t}
        '') selected}

        # Completeness guard: every file herdr wrote must be one we either copy
        # out or translate into Nix. An integration that grows an artifact we do
        # not link is worse than useless — it half-works, silently.
        find "$HOME" -type f -printf '%P\n' | sort > actual.txt
        printf '%s\n' ${escapeShellArgs (sort lessThan (selectedFiles ++ translatedFiles))} \
          | sort > accounted.txt
        if ! ${pkgs.diffutils}/bin/diff -u accounted.txt actual.txt; then
          echo >&2
          echo "herdr wrote a different set of files than home-modules/herdr-integrations.nix" >&2
          echo "declares in knownTargets (- missing, + unaccounted). Update it to match." >&2
          exit 1
        fi

        ${concatMapStringsSep "\n" (p: ''install -Dm444 "$HOME/${p}" "$out/files/${p}"'') selectedFiles}

        ${optionalString wantsClaude ''
          ${normalise ''"$HOME/.claude/settings.json"''} > wanted.json
          ${normalise declaredRegistration} > declared.json
          if ! ${pkgs.diffutils}/bin/diff -u wanted.json declared.json; then
            echo >&2
            echo "herdr's Claude hook registration no longer matches mkClaudeRegistration" >&2
            echo "in home-modules/herdr-integrations.nix. Update it to the 'wanted' side" >&2
            echo "above (the blanked @CMD@ field is ours to choose; nothing else is)." >&2
            exit 1
          fi
        ''}
      '';
in
{
  options.programs.herdr.integrations = mkOption {
    type = types.listOf (types.enum (attrNames knownTargets));
    default = [ ];
    example = [
      "claude"
      "pi"
    ];
    description = ''
      Agent integrations to install declaratively, letting each agent report
      its state to herdr rather than having herdr infer it from process
      detection. List only agents this machine actually installs.

      These replace `herdr integration install`; running that by hand (or via
      herdr's settings UI) is unnecessary, and for Claude it cannot work —
      registration lives in the Nix-owned {file}`~/.claude/settings.json`.
    '';
  };

  config = mkIf (cfg.enable && selected != [ ]) {
    home.file = listToAttrs (
      map (p: nameValuePair p { source = "${integrations}/files/${p}"; }) selectedFiles
    );

    # Nix is the only writer of this file, so there is no merge to lose against
    # herdr — it cannot write here at all. Guarded so listing "claude" on a host
    # without claude-code does not switch that module on.
    programs.claude-code.settings.hooks = mkIf (wantsClaude && config.programs.claude-code.enable) (
      mkClaudeRegistration "bash ${integrations}/files/.claude/hooks/herdr-agent-state.sh session"
    );
  };
}
