{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.kubeswitch;
in {
  options.programs.kubeswitch = {
    enable = mkEnableOption "kubeswitch";

    package = mkOption {
      type = types.package;
      default = pkgs.kubeswitch;
    };

    shellAlias = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = [
        # we need switcher to be in the PATH to use kubeswitch
        cfg.package
      ];

      shellAliases = lib.mkIf (cfg.shellAlias != null) {
        ${cfg.shellAlias} = "kubeswitch";
      };
    };

    # For some reason the completion logic is not being picked up by fish.
    # Force a completion file for "kubeswitch" to be generated (default is "switcher").
    # Small hack to fix the completion script to use the switcher binary directly.
    xdg.configFile."fish/completions/kubeswitch.fish".source = pkgs.runCommand "kubeswitch-fish-completion" {} ''
      ${cfg.package}/bin/switcher completion -c kubeswitch fish | \
        ${pkgs.gnused}/bin/sed 's|\$args\[1\]|${cfg.package}/bin/switcher|' \
        > $out
    '';

    programs = {
      bash.initExtra = ''
        source <("${cfg.package}/bin/switcher init bash")
      '';

      fish.interactiveShellInit = ''
        ${cfg.package}/bin/switcher init fish | source
      '';

      zsh.initExtra = ''
        source <("${cfg.package}/bin/switcher init zsh")
      '';
    };
  };
}
