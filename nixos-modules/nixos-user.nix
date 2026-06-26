{ user, ... }:
let
  inherit (user) login;
  homeDir = "/home/${login}";
in
{
  nix.settings.trusted-users = [
    login
  ];

  users.users.${login}.home = homeDir;
}
