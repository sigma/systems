{ inputs, lib, ... }:
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
        inherit (inputs'.nixpkgs-stable.legacyPackages) nixos-rebuild;
        inherit (inputs'.home-manager.packages) home-manager;
        nixos-generate = inputs'.nixos-generators.packages.nixos-generate;
      }
      // lib.optionalAttrs pkgs'.stdenv.isDarwin {
        inherit (inputs'.darwin.packages) darwin-rebuild;
      }
      // pkgs'.local;
    };
}
