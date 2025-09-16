{ user, ... }:
{
  virtualisation.docker.enable = true;
  users.users.${user.login}.extraGroups = [
    "docker"
  ];
}
