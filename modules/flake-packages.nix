{ inputs, ... }:
{
  perSystem =
    {
      system,
      inputs',
      ...
    }:
    let
      pkgs' = import inputs.nixpkgs (
        {
          inherit system;
        }
        // (import ../pkg-config.nix {
          inherit inputs;
        })
      );
    in
    {
      packages = {
        inherit (inputs'.darwin.packages) darwin-rebuild;
        inherit (inputs'.nixpkgs-stable.legacyPackages) nixos-rebuild;
        inherit (inputs'.home-manager.packages) home-manager;
      }
      // pkgs'.local;
    };
}
