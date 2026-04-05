{ lib, machine, ... }:
with lib;
let
  kbd = import ../keyboards.nix;
in
{
  config = mkIf (!machine.features.laptop && machine.features.mac) {
    programs.karabiner =
      let
        k8Pro = kbd.keychron 640;
        wirelessLink = kbd.keychron 53296;
        usbPedal = {
          vendorId = 13651;
          productId = 45057;
        };
      in
      {
        enable = mkForce true;

        ignoreKeyboards = [
          k8Pro
          wirelessLink
        ];
        pedal = usbPedal;
        pedalComboDevice = true;
        pedalKeys = {
          left = "a";
          middle = "b";
          right = "c";
        };
      };
  };
}
