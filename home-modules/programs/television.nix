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
# Gated on tv being enabled (it follows the shell content feature, which the
# devbox policy turns off). The fish `type -q` guard also no-ops on any machine
# without atuin.
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
  config = lib.mkMerge [
    # television (tv) — the primary interactive fuzzy finder.
    #
    # fzf is intentionally kept alongside tv for the tools tv can't replace:
    # the fzf-fish widgets (Ctrl+Alt+F/L/S/P, Ctrl+V), tmux-fzf, fzf-tmux-url,
    # zoxide's `zi`, and neovim's telescope-fzf-native (the fzf algorithm as a
    # library). See ../settings/programs/fzf.nix.
    #
    # Shell integration binds Ctrl+T (smart autocomplete). tv also binds Ctrl+R
    # to its own history, but atuin owns Ctrl+R here, so the wiring below hands
    # Ctrl+R back to atuin after tv loads, and adds the nushell integration
    # (this HM version's module only supports fish/bash/zsh).
    {
      programs.television = {
        enable = lib.mkDefault (config.features.shell.enable);

        # Default/stable nixpkgs pin tv 0.13.10, which is too old to parse the
        # current config schema and shell-init format. Track master for a recent
        # release (0.15.x).
        package = pkgs.master.television;

        enableFishIntegration = true;
      };
    }

    (lib.mkIf cfg.enable {
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
    })
  ];
}
