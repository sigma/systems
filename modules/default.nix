{...}: {
  imports = [
    # shell support
    ./shell.nix

    # definitions for machine types, hosts, users.
    ./defs

    # configurations for home-manager, darwin, etc.
    ./configurations
  ];
}
