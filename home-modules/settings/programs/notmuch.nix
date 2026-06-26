{ config, ... }:
{
  inherit (config.programs.mailsetup) enable;
  new = {
    tags = [ "new" ];
  };
}
