{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.alfred;
in
{
  options.programs.alfred = {
    enable = mkEnableOption "alfred";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      "alfred"
    ];

    # Disable spotlight shortcuts
    system.defaults.CustomUserPreferences."com.apple.symbolichotkeys".AppleSymbolicHotKeys."64" = {
      enabled = false;
      value = {
        parameters = [
          32
          49
          1048576
        ];
        type = "standard";
      };
    };
    system.defaults.CustomUserPreferences."com.apple.symbolichotkeys".AppleSymbolicHotKeys."65" = {
      enabled = false;
      value = {
        parameters = [
          32
          49
          1572864
        ];
        type = "standard";
      };
    };
  };
}
