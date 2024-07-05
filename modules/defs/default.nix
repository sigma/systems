{
  inputs,
  lib,
  ...
}: {
  config = let
    stateVersion = "23.11";
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
