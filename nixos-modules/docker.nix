{ user, lib, machine, ... }:
lib.mkIf (!machine.features.devbox) {
  virtualisation.docker.enable = true;
  virtualisation.docker.listenOptions = [
    "/run/docker.sock"
    "localhost:2376"
  ];

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  users.users.${user.login}.extraGroups = [
    "docker"
  ];
}
