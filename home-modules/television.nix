# Television shell wiring that the home-manager module doesn't cover:
# hand Ctrl+R back to atuin, and add the nushell integration by hand.
#
# tv's `init` binds Ctrl+T (smart autocomplete) *and* Ctrl+R (its own
# history) in each shell. We want Ctrl+T but atuin owns Ctrl+R here, so:
#   - fish:    HM sources `tv init fish`; re-bind Ctrl+R to atuin's
#              `_atuin_search` afterwards (mkAfter = last wins).
#   - nushell: HM has no television integration in this version, so source
#              `tv init nu` ourselves, then drop tv's `tv_history`
#              keybinding so atuin's Ctrl+R survives.
#
# Gated on tv being enabled, so devboxes (which don't load the tv settings
# module) skip this entirely. The fish `type -q` guard also no-ops on any
# machine without atuin.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.television;
  # Generate `tv init nu` once at build time and source it from config.nu.
  # tv wants a writable HOME to resolve its config dir; the sandbox HOME is
  # read-only, so point it at a scratch dir.
  tvInitNu = pkgs.runCommand "television-init.nu" { } ''
    export HOME="$(mktemp -d)"
    ${lib.getExe cfg.package} init nu > $out
  '';
in
{
  config = lib.mkIf cfg.enable {
    programs.fish.interactiveShellInit = lib.mkAfter ''
      if type -q _atuin_search
          bind ctrl-r _atuin_search
          bind -M insert ctrl-r _atuin_search
      end
    '';

    programs.nushell.extraConfig = lib.mkAfter ''
      source ${tvInitNu}
      # Keep Ctrl+R on atuin: drop tv's history keybinding.
      $env.config.keybindings = (
        $env.config.keybindings | where {|k| ($k.name? | default "") != "tv_history"}
      )
    '';
  };
}
