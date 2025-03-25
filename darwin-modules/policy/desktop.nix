{lib, ...}: {
  programs.karabiner = with lib; let
    keychron = pid: {
      vendorId = 13364;
      productId = pid;
    };
    k8Pro = keychron 640;
    wirelessLink = keychron 53296;
    usbPedal = {
      vendorId = 13651;
      productId = 45057;
    };
  in {
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
}
