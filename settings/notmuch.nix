{ config, pkgs, user, ... }:

{
  enable = true;
  new = {
    ignore = [ "/.*[.](json|lock|bak)$/" ];
    tags = [ "new" ];
  };
}
