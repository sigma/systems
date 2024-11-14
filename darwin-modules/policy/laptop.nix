{lib, ...}: {
  programs.karabiner = with lib; let
    keychron = pid: {
      vendorId = 13364;
      productId = pid;
    };
    q1Max = keychron 2064;
    massdrop = pid: {
      vendorId = 1240;
      productId = pid;
    };
    ctrl = massdrop 61138;
    wirelessLink = keychron 53296;
    kinesisPedal = {
      vendorId = 10730;
      productId = 256;
    };
  in {
    # I always use karabiner on my laptops
    enable = mkForce true;

    # My docking stations for laptops.
    ignoreKeyboards = [
      # home
      q1Max
      wirelessLink
      # office
      ctrl
    ];
    pedal = kinesisPedal;
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
