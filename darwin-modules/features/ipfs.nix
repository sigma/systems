{
  config,
  lib,
  pkgs,
  user,
  ...
}:
with lib;
let
  cfg = config.features.ipfs;
in
{
  options.features.ipfs = {
    enable = mkEnableOption "ipfs";
  };

  config = mkIf cfg.enable {
    services.ipfs = {
      enable = true;
      enableGarbageCollection = true;
      package = pkgs.ipfs;
    };

    home-manager.users.${user.login} = {
      home.packages = with pkgs; [
        ipfs
      ];
    };
  };
}
