user:
{ config, lib, pkgs, ... }:

let
  homeDir = "/Users/${user}";
in
{
  nix.trustedUsers = [
    user
  ];

  users.users.${user}.home = homeDir;

  services.link-apps = {
    enable = true;
    userName = user;
    userHome = homeDir;
  };
}
