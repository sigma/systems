{...}: {
  imports = [
    # introduce proper options for homeConfigurations and darwinConfigurations.
    # Also add a defs option for the definitions module below.
    ./flake-options.nix

    # shell support
    ./shell.nix

    # definitions for machine types, hosts, users.
    ./defs

    # configurations for home-manager, darwin, etc.
    ./configurations
  ];
}