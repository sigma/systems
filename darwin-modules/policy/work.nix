{ lib, machine, ... }:
with lib;
{
  config = mkIf machine.features.work {
  };
}
