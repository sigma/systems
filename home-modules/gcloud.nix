{
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.gcloud;
in {
  options.programs.gcloud = {
    enable = mkEnableOption "Google Cloud SDK";

    package = mkOption {
      type = types.package;
      default = google-cloud-sdk;
    };

    enableGkeAuthPlugin = mkEnableOption "GKE auth plugin";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; let
      pkg =
        if cfg.enableGkeAuthPlugin
        then cfg.package.withExtraComponents [google-cloud-sdk.components.gke-gcloud-auth-plugin]
        else cfg.package;
    in [
      pkg
    ];
  };
}
