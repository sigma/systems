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
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      kubeswitch
    ];

    programs.bash = {
      shellAliases = {
        "sw" = "kubeswitch";
      };

      initExtra = ''
        source <(${pkgs.kubeswitch}/bin/switcher init bash)
      '';
    };

    programs.fish = {
      shellAliases = {
        "sw" = "kubeswitch";
      };

      interactiveShellInit = ''
        ${pkgs.kubeswitch}/bin/switcher init fish | source
      '';
    };

    programs.zsh = {
      shellAliases = {
        "sw" = "kubeswitch";
      };

      initExtra = ''
        source <(${pkgs.kubeswitch}/bin/switcher init zsh)
      '';
    };
  };
}
