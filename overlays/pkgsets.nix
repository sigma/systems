inputs:
  final: prev: let
    system = final.stdenv.system;
    nixpkgs-stable =
      if final.stdenv.isDarwin
      then inputs.darwin-stable
      else inputs.nixos-stable;
  in {
    master = inputs.nixpkgs-master.legacyPackages.${system};
    stable = nixpkgs-stable.legacyPackages.${system};
  }