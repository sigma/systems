{ inputs, ... }:
rec {
  config = {
    allowUnfree = true;
  };
  overlays = import ./overlays {
    inherit inputs config;
  };
}
