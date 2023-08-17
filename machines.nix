{ inputs }:

let
  users = import ./users.nix;
  # Configuration for `nixpkgs`
  nixpkgsConfig = rec {
    config = {allowUnfree = true;};
    overlays = import ./overlays.nix { inherit inputs config; };
  };
  hmModules = [
    ./home.nix
    inputs.nix-doom-emacs.hmModule
  ];
  darwinModules = {};
in
{
  inherit darwinModules;

  mac = machine: let
    user =
      if machine.isWork
      then users.corpUser
      else users.personalUser;
    specialArgs = {
      inherit user machine;
      isMac = true;
    };
  in
    inputs.darwin.lib.darwinSystem {
      inherit (machine) system;
      inherit specialArgs;
      modules =
        inputs.nixpkgs.lib.attrValues darwinModules
        ++ inputs.nixpkgs.lib.optionals (machine.isWork) [
          ({ ... }: {
            # those files are handled by corp and will be reverted anyway, so
            # skip the warning about them being overwritten.
            environment.etc."shells".copy = true;
            environment.etc."zshrc".copy = true;
            # leave bashrc alone, I don't use bash
            environment.etc."bashrc".enable = false;
          })
        ]
        ++ [
          # Main `nix-darwin` config
          ./configuration.nix
          ./mac-user.nix
          # `home-manager` module
          inputs.home-manager.darwinModules.home-manager
          {
            nixpkgs = nixpkgsConfig;
            # `home-manager` config
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${user.login} = inputs.nixpkgs.lib.mkMerge hmModules;
            home-manager.extraSpecialArgs = specialArgs;
          }
        ];
    };

  glinux = machine: let
    user = users.corpUser;
    specialArgs = {
      inherit user;
      machine =
        {
          isInteractive = false;
          system = "x86_64-linux";
        }
        // machine
        // {isWork = true;};
      isMac = false;
    };
  in
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = builtins.getAttr "x86_64-linux" inputs.nixpkgs.outputs.legacyPackages // nixpkgsConfig;
      modules =
        hmModules
        ++ [
          {
            home = {
              username = user.login;
              homeDirectory = "/usr/local/google/home/${user.login}";
              stateVersion = "23.05";
            };
          }
        ];
      extraSpecialArgs = specialArgs;
    };
}
