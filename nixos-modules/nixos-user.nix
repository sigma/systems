{ config, user, ... }:
let
  inherit (user) login;
  homeDir = "/home/${login}";
in
{
  nix.settings.trusted-users = [
    login
  ];

  users.users.${login} = {
    home = homeDir;
    # Rex's personal server is a systemd user service (home-modules/programs/rex.nix);
    # linger starts it at boot and keeps sessions alive across logout.
    linger = config.home-manager.users.${login}.services.rex.enable;
  };
}
