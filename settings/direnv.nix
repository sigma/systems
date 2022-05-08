{ config, ... }:

{
  enable = true;
  nix-direnv.enable = true;
  stdlib = ''
    # plop
  '';
}
