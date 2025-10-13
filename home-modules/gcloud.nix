{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.gcloud;
in
{
  options.programs.gcloud = {
    enable = mkEnableOption "Google Cloud SDK";

    basePackage = mkPackageOption pkgs "google-cloud-sdk" {
      nullable = true;
    };

    package = mkOption {
      type = types.package;
      readOnly = true;
      description = "Resulting customized Google Cloud SDK package.";
    };

    extraComponents = mkOption {
      default = components: [ ];
      description = "Extra components to install.";
      example = components: [ components.gke-gcloud-auth-plugin ];
      type = types.functionTo (types.listOf types.package);
    };
  };

  config = mkIf cfg.enable {
    programs.gcloud.package = cfg.basePackage.withExtraComponents (
      cfg.extraComponents cfg.basePackage.components
    );

    home.packages = [
      cfg.package
    ];
  };
}
