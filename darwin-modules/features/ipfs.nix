{
  config,
  lib,
  pkgs,
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

    user = {
      home.packages = with pkgs; [
        ipfs
      ];
    };
  };
}
