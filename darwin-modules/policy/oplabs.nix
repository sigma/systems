{
  lib,
  machine,
  ...
}:
with lib; {
  programs.onepassword.enable = mkForce true;

  programs.karabiner = mkIf machine.features.laptop {
    # that's horrendous, but for whatever reason the M3 MBP isn't detected
    # properly by karabiner. That means I'll have to connect it only to
    # keyboards that are ignored (which fortunately is the case)
    internalKeyboardID = {
      is_keyboard = true;
    };
  };
}
