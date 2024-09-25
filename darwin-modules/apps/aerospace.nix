{
  config,
  lib,
  user,
  ...
}:
with lib; let
  cfg =
    config.programs.aerospace
    // {
      inherit (config.homebrew) brewPrefix;
    };
in {
  options.programs.aerospace = {
    enable = mkEnableOption "Aerospace";

    autostart = mkOption {
      type = types.bool;
      default = true;
      description = "Autostart Aerospace at login";
    };

    borders = mkOption {
      type = types.bool;
      default = true;
      description = "Enable borders";
    };
  };

  config = mkIf cfg.enable {
    homebrew = {
      taps =
        [
          "nikitabobko/tap"
        ]
        ++ optionals cfg.borders [
          "FelixKratz/formulae"
        ];
      brews = optionals cfg.borders [
        "borders"
      ];
      casks = [
        "aerospace"
      ];
    };

    home-manager.users.${user.login}.home.file.".aerospace.toml".text = import ./aerospace/config.nix cfg;
  };
}
