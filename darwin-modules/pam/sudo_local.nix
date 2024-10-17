# This module applies only starting with Sonoma (14.5)
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.security.pam.sudo_local;
  formatEntry = entry: "${entry.type}\t${entry.control}\t${entry.module}\t${concatStringsSep " " entry.arguments} # nix-darwin: ${entry.comment}";
  text = lib.concatStringsSep "\n" (builtins.map formatEntry cfg.entries);
in {
  options.security.pam.sudo_local = {
    entries = mkOption {
      type = types.listOf (types.submodule {
        options = {
          type = mkOption {
            type = types.enum ["auth" "account" "password" "session"];
            default = "auth";
          };
          control = mkOption {
            type = types.enum ["required" "requisite" "sufficient" "optional" "include" "substack"];
            default = "optional";
          };
          module = mkOption {
            type = types.str;
          };
          arguments = mkOption {
            type = types.listOf types.str;
            default = [];
          };
          comment = mkOption {
            type = types.str;
            default = "security.pam.sudo_local";
          };
        };
      });
    };
  };

  config = {
    environment.etc."pam.d/sudo_local" = {
      inherit text;
    };
  };
}
