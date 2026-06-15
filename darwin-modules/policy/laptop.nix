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

    programs.kanata = {
      enable = mkForce true;

      # Include-list: only these devices are intercepted; QMK docking-
      # station keyboards (Keychron Q1 Max, Massdrop CTRL, Keychron
      # Wireless Link) are not listed and pass through untouched.
      devices = [
        "Apple Internal Keyboard / Trackpad"
        # Kinesis Savant Elite2 pedal; must be reflashed to emit
        # F20/F21/F22 from left/right/middle (kanata cannot grab the
        # default mouse-button HID events).
        "Kinesis Savant Elite2"
      ];

      mods = {
        swapAltCmd = true;
        fnDndHack = true;
        hyperFromLctl = true;
        capsEscCtrl = true;
        enterRctrl = true;
        shiftParens = true;
        bracketChords = true;
      };

      # 80ms (default) mistriggered on "xc" bigrams (e.g. "exception")
      # and "./" sequences. 30ms requires a near-simultaneous press
      # for the chord to register, which rules out rolling typing.
      timing.chordMs = 30;

      pedal = {
        left = "f18"; # paired with macOS Dictation Shortcut = F18
        right = "ret";
        middle = "lmet";
      };
    };
  };
}
