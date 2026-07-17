{ config, ... }:
{
  inherit (config.features.shell) enable;
  enableFishIntegration = true;
}
