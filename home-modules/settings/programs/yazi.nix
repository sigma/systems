{ config, ... }:
{
  enable = config.features.shell.enable;
  enableFishIntegration = true;
}
