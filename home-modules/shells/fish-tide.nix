# An extension of the fish module to use and configure the tide prompt.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.fish;
in
with lib;
{
  options = {
    programs.fish = {
      useTide = mkOption {
        type = types.bool;
        default = false;
      };

      tideOptions = mkOption {
        type = types.listOf types.str;
        default = [ ];
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

      tideOverrides = mkOption {
        type = types.attrsOf types.str;
        default = { };
      };
    };
  };

  config = mkIf cfg.enable {
    # Add TTY guard as earliest conf.d file to prevent hangs with VS Code Remote SSH
    # This file is sourced before plugins (alphabetically: 00- < plugin-)
    # Note: `exit` in sourced files doesn't exit fish, so we use `exec true` to replace the shell
    xdg.configFile."fish/conf.d/00-tty-guard.fish".text = ''
      # Skip shell initialization if interactive but no TTY (e.g., VS Code Remote SSH with -T)
      # This prevents hangs when SSH tries interactive session without PTY
      # Only bail out if BOTH: no TTY AND fish thinks it's interactive
      # Commands like `ssh -T host "echo hello"` run non-interactively and should work
      if status is-interactive; and not isatty stdin
          exec true
      end
    '';

    programs.fish.plugins = lib.optionals cfg.useTide [
      {
        name = "tide";
        inherit (pkgs.fishPlugins.tide) src;
      }
    ];

    home.activation = lib.optionalAttrs (cfg.useTide && cfg.tideOptions != [ ]) {
      configureTide =
        let
          flags = builtins.concatStringsSep " " cfg.tideOptions;
          overrides = builtins.concatStringsSep "\n" (
            lib.mapAttrsToList (k: v: ''${pkgs.fish}/bin/fish -c "set -Ux tide_${k} ${v}"'') cfg.tideOverrides
          );
        in
        lib.hm.dag.entryAfter [ "writeBoundary" ] (
          ''
            echo "Configuring tide prompt"
            # Suppress output so that the screen isn't cleared
            ${pkgs.fish}/bin/fish -c "tide configure --auto ${flags} > /dev/null 2>&1"
            echo "Setting tide prompt segments"
            ${pkgs.fish}/bin/fish -c "set -Ux tide_left_prompt_items ${builtins.concatStringsSep " " cfg.tideLeftSegments}"
            ${pkgs.fish}/bin/fish -c "set -Ux tide_right_prompt_items ${builtins.concatStringsSep " " cfg.tideRightSegments}"
          ''
          + lib.optionalString (cfg.tideOverrides != { }) overrides
        );
    };
  };
}
