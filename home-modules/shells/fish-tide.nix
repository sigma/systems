# An extension of the fish module to use and configure the tide prompt.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.fish;
in
  with lib; {
    options = {
      programs.fish = {
        useTide = mkOption {
          type = types.bool;
          default = false;
        };

        tideOptions = mkOption {
          type = types.listOf types.str;
          default = [];
        };

        tideLeftSegments = mkOption {
          type = types.listOf types.str;
          default = [
            "os"
            "pwd"
            "git"
            "newline"
            "character"
          ];
        };

        tideRightSegments = mkOption {
          type = types.listOf types.str;
          default = [
            "status"
            "cmd_duration"
            "context"
            "jobs"
            "direnv"
            "python"
            "rustc"
            "java"
            "ruby"
            "go"
            "gcloud"
            "kubectl"
            "distrobox"
            "toolbox"
            "terraform"
            "aws"
            "nix_shell"
          ];
        };
      };
    };

    config = mkIf cfg.enable {
      programs.fish.plugins = lib.optionals cfg.useTide [
        {
          name = "tide";
          inherit (pkgs.fishPlugins.tide) src;
        }
      ];

      home.activation = lib.optionalAttrs (cfg.useTide && cfg.tideOptions != []) {
        configureTide = let
          flags = builtins.concatStringsSep " " cfg.tideOptions;
        in
          lib.hm.dag.entryAfter ["writeBoundary"] ''
            echo "Configuring tide prompt"
            # Suppress output so that the screen isn't cleared
            ${pkgs.fish}/bin/fish -c "tide configure --auto ${flags} > /dev/null 2>&1"
            echo "Setting tide prompt segments"
            ${pkgs.fish}/bin/fish -c "set -Ux tide_left_prompt_items ${builtins.concatStringsSep " " cfg.tideLeftSegments}"
            ${pkgs.fish}/bin/fish -c "set -Ux tide_right_prompt_items ${builtins.concatStringsSep " " cfg.tideRightSegments}"
          '';
      };
    };
  }
