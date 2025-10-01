{ lib, machine, ... }:
with lib;
{
  config = mkIf machine.features.laptop {
    # This accounts for my docking stations.
    # Home config (laptop closed):
    # - main monitor is Dell
    # - secondary monitor is LG
    # Home config (laptop open):
    # - main monitor is Dell
    # - secondary monitor is LG
    # - built-in monitor is the laptop screen
    # Office config (laptop always open):
    # - main monitor is Apple
    # - secondary monitor is the laptop screen
    # Travel config (laptop + zenscreen):
    # - main monitor is the laptop screen
    # - secondary monitor is the zenscreen
    # Mobile config (laptop only):
    # - main monitor is the laptop screen
    programs.aerospace.monitors =
      let
        zenscreen = "ASUS MB16AC";
        lg = "LG SDQHD";
        force_side = [
          zenscreen
          "built-in"
          "secondary"
          "main"
        ];
      in
      {
        browser = "main";
        chat = force_side;
        # use the vertical monitor for coding if it's there
        editor = [
          lg
          "main"
        ];
        music = "main";
        notes = force_side;
        terminal = [
          "built-in"
          "main"
        ];
      };

    programs.karabiner =
      with lib;
      let
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
      in
      {
        # I always use karabiner on my laptops
        enable = mkForce true;

        # My docking stations for laptops are connected to QMK keybaords,
        # so I don't need Karabiner to handle them.
        ignoreKeyboards = [
          # home
          q1Max
          wirelessLink
          # office
          ctrl
        ];
        pedal = kinesisPedal;
      };
  };
}
