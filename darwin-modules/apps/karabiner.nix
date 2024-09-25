{
  config,
  lib,
  user,
  ...
}:
with lib; let
  cfg = config.programs.karabiner;
  cfgTxt = builtins.toJSON (import ./karabiner/config.nix {inherit lib;});
in {
  options.programs.karabiner = {
    enable = mkEnableOption "Karabiner";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      "karabiner-elements"
    ];
    home-manager.users.${user.login}.home.file.".config/karabiner/karabiner.json".text = cfgTxt;
  };
}
