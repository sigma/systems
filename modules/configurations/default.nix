{self, ...}:
{
  flake = let
    inherit (self.defs) machines hosts;
  in
    {
      # My `nix-darwin` configs
      darwinConfigurations = {
        yhodique-macbookpro = machines.mac hosts.yhodique-macbookpro;
        yhodique-macmini = machines.mac hosts.yhodique-macmini;
      };

      # My home-manager only configs
      homeConfigurations = {
        # glinux is an anonymous profile, useful for dynamically created
        # instances that I can't be bothered to register here.
        glinux = machines.glinux {};
        shirka = machines.glinux hosts.shirka;
        ghost-wheel = machines.glinux hosts.ghost-wheel;
      };
    }; 
}