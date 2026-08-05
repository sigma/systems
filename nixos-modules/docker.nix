{
  user,
  lib,
  machine,
  pkgs,
  ...
}:
{
  virtualisation.docker.enable = true;
  # The module default is pkgs.docker == docker_28, which nixpkgs marks insecure
  # (unmaintained since Nov 2025).
  virtualisation.docker.package = pkgs.docker_29;
  virtualisation.docker.listenOptions = [
    "/run/docker.sock"
    "localhost:2376"
  ];

  # Rootless on devboxes adds linger + per-user-service-enable friction
  # without any real benefit on a single-user VM. System docker is enough.
  virtualisation.docker.rootless = {
    enable = !machine.features.devbox;
    setSocketVariable = !machine.features.devbox;
  };

  users.users.${user.login}.extraGroups = [
    "docker"
  ];
}
