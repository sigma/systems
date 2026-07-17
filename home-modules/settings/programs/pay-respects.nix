{ config, ... }:
{
  inherit (config.features.shell) enable;
  options = [
    "--alias"
    "f"
  ];
}
