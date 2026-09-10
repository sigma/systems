{ config, ... }:
{
  inherit (config.features.shell) enable;
  enableFishIntegration = true;
  # Pin the shell wrapper name: home-manager 26.05 moved the default from "yy"
  # to "y" and warns until the option is set explicitly. We take the new default.
  shellWrapperName = "y";
}
