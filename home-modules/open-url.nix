{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.open-url;

  launchBrowser =
    browser: if hasSuffix ".app" "${browser}" then "open -n -a '${browser}' --args" else "${browser}";
in
{
  options.programs.open-url = {
    enable = mkEnableOption "open-url";

    browser = mkOption {
      type = types.str;
      default = "${pkgs.chromium}/bin/chromium";
    };

    localStatePath = mkOption {
      type = types.str;
      default = "";
    };

    urlProfiles = mkOption {
      type = types.attrsOf types.str;
      default = {
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellScriptBin "open-url" ''
        URL="$1"
        PROFILE_NAME=""

        shopt -s nocasematch
        ${
          (builtins.concatStringsSep "\n" (
            mapAttrsToList (url: profile: ''
              if [[ "$URL" =~ "${url}" ]]; then
                PROFILE_NAME="${profile}"
              fi
            '') cfg.urlProfiles
          ))
        }
        shopt -u nocasematch

        if [[ -n "$PROFILE_NAME" ]]; then
          STATE_FILE="${cfg.localStatePath}"
          # Parse Local State file to get profile directory mapping
          PROFILE=$(${pkgs.jq}/bin/jq -r --arg name "$PROFILE_NAME" '.profile.info_cache | to_entries[] | select(.value.name == $name) | .key' "$STATE_FILE")
        fi


        if [[ -n "$PROFILE" ]]; then
          ${launchBrowser cfg.browser} --profile-directory="$PROFILE" "$URL"
        else
          ${launchBrowser cfg.browser} --profile-directory="Default" "$URL"
        fi
      '')
    ];
  };
}
