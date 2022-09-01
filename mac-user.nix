{ user, config, lib, pkgs, ... }:

let
  login = user.login;
  homeDir = "/Users/${login}";
in
{
  nix.trustedUsers = [
    login
  ];

  users.users.${login}.home = homeDir;

  services.link-apps = {
    enable = true;
    userName = login;
    userHome = homeDir;
  };
}
