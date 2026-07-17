{ config, ... }:
{
  enable = config.features.shell.enable;
  options = [
    "--alias"
    "f"
  ];
}
