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

  # Hack for karabiner: register F16 as the "do not disturb" shortcut.
  system.defaults = {
    CustomUserPreferences = {
      "com.apple.symbolichotkeys" = {
        AppleSymbolicHotKeys = {
          "175" = {
            enabled = true;
            value = {
              parameters = [65535 106 8388608];
              type = "standard";
            };
          };
        };
      };
    };
  };
}
