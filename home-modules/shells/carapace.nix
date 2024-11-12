{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.carapace;
in {
  options = {
    programs.carapace = {
      fishNative = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Completions to use fish native completions for.";
      };
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile =
      builtins.listToAttrs (map (cmd: {
          name = "fish/completions/${cmd}.fish";
          value = {
            enable = mkForce false;
          };
        })
        cfg.fishNative)
      // {
        "carapace/bridges.yaml".text = ''
          ${builtins.concatStringsSep "\n" (map (cmd: "${cmd}: fish") cfg.fishNative)}
        '';
      };

    programs.fish.shellInitLast = mkAfter ''
      set -gx CARAPACE_EXCLUDES ${builtins.concatStringsSep "," cfg.fishNative}
    '';
  };
}
