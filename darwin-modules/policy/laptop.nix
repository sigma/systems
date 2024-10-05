{lib, ...}: {
  programs.karabiner = with lib; let
    keychron = pid: {
      vendorId = 13364;
      productId = pid;
    };
    q1Max = keychron 2064;
    wirelessLink = keychron 53296;
    kinesisPedal = {
      vendorId = 10730;
      productId = 256;
    };
  in {
    # I always use karabiner on my laptops
    enable = mkForce true;

    # My docking station for laptops.
    ignoreKeyboards = [
      q1Max
      wirelessLink
    ];
    pedal = kinesisPedal;
  };
}
