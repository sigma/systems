{ user, ... }:
let
  inherit (user) login;
  homeDir = "/Users/${login}";
in
{
  nix.settings.trusted-users = [
    login
  ];

  users.users.${login}.home = homeDir;
}
