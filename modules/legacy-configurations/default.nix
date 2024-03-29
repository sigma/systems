{inputs, ...}:
{
  flake = let
    stateVersion = "23.11";
    hosts = import ../../hosts.nix {
      lib = import inputs.nixpkgs-lib;
    };
    machines = import ../../machines.nix {inherit inputs stateVersion; };
  in
    {
      # My `nix-darwin` configs
      darwinConfigurations = {
        yhodique-macbookpro = machines.mac hosts.yhodique-macbookpro;
        yhodique-macmini = machines.mac hosts.yhodique-macmini;
      };
      inherit (machines) darwinModules;

      # My home-manager only configs
      homeConfigurations = {
        glinux = machines.glinux {};
        shirka = machines.glinux hosts.shirka;
        ghost-wheel = machines.glinux hosts.ghost-wheel;
      };
    }; 
}