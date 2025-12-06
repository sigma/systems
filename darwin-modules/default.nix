{ ... }:
{
  imports = [
    ./apps
    ./features
    ./gui.nix
    ./interface
    ./mac-user.nix
    ./nix.nix
    ./pam
    ./policy
    ./system.nix
    ./u2f-keys.nix
    ./versions.nix
  ];
}
