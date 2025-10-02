{ config, ... }:
{
  enable = config.programs.mailsetup.enable;
  new = {
    tags = [ "new" ];
  };
}
