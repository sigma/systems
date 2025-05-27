{
  inputs,
  config,
  ...
}: final: prev: let
  system = final.stdenv.system;
  nixpkgs-stable =
    if final.stdenv.isDarwin
    then inputs.darwin-stable
    else inputs.nixos-stable;
  extra86 = pkgset:
    import pkgset {
      system = "x86_64-darwin";
      inherit config;
    };
in
  {
    master = inputs.nixpkgs-master.legacyPackages.${system};
    stable = nixpkgs-stable.legacyPackages.${system};

    # put determinate nix in a separate package set so we can decide which
    # version to use depending on the machine.
    determinate = {
      nix = inputs.nix.packages.${system}.nix;
    };
  }
  // inputs.nixpkgs.lib.optionalAttrs (prev.stdenv.system == "aarch64-darwin") {
    x86 =
      (extra86 inputs.nixpkgs)
      // {
        master = extra86 inputs.nixpkgs-master;
        stable = extra86 nixpkgs-stable;
      };
  }
