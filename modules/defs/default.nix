{
  inputs,
  lib,
  ...
}: {
  config = let
    stateVersion = "24.05";
    users = import ./users.nix;
    hosts = import ./hosts.nix {
      inherit lib;
    };
    machines = import ./machines.nix {
      inherit inputs stateVersion users;
    };
  in {
    defs = {
      inherit hosts machines users;
    };
  };
}
