{lib, ...}: {
  programs.karabiner = with lib; {
    # I always use karabiner on my laptops
    enable = mkForce true;

    # My docking station.
    # ignore the q1 max keyboard and its wireless link
    ignoreKeyboards = [
      # q1 max
      {
        vendorId = 13364;
        productId = 2064;
      }
      # wireless link
      {
        vendorId = 13364;
        productId = 53296;
      }
    ];

    pedal = {
      vendorId = 10730;
      productId = 256;
    };
  };
}
