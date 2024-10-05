{
  config,
  lib,
  pkgs,
  user,
  ...
}:
with lib; let
  cfg = config.programs.aerospace;

  workspaceType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Name of the workspace";
      };
      display = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Display the workspace is connected to";
      };
    };
  };

  windowRuleType = types.submodule {
    options = {
      appId = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Application ID to match";
      };
      appNameRegexSubstring = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Application name regex substring to match";
      };
      windowTitleRegexSubstring = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Window title regex substring to match";
      };
      workspace = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Workspace to move the window to";
      };
      layout = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Layout to apply to the window";
      };
    };
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

    workspaces = mkOption {
      type = types.listOf workspaceType;
      default = [];
      description = "List of workspaces defined for this configuration";
    };

    windowRules = mkOption {
      type = types.listOf windowRuleType;
      default = [];
      description = "List of window rules for automatic window management";
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

    home-manager.users.${user.login}.home.file.".aerospace.toml".text = import ./aerospace/config.nix {
      inherit lib pkgs;
      inherit (cfg) autostart borders workspaces windowRules;
      bordersBinary = "${config.homebrew.brewPrefix}/borders";
    };
  };
}
