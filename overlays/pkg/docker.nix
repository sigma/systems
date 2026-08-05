# TEMPORARY: docker_28 is marked insecure (unmaintained since Nov 2025) but
# nixpkgs still defaults `docker` to docker_28. Override so every module that
# uses `pkgs.docker` (including virtualisation.docker.rootless) gets docker_29.
# Remove once nixpkgs updates the default alias.
final: prev: {
  docker = prev.docker_29;
}
