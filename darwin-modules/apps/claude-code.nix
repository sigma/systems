# Darwin module for Claude Code via Homebrew
#
# This module enables the home-manager claude-code module with a package
# that wraps the homebrew-installed claude binary.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.claude-code;
in
{
  options.programs.claude-code = {
    enable = mkEnableOption "Claude Code CLI (via Homebrew)";
  };

  config = mkIf cfg.enable {
    user.programs.claude-code = {
      enable = true;
      # Create a wrapper that delegates to homebrew-installed claude
      package = pkgs.writeShellScriptBin "claude" ''
        exec ${config.homebrew.brewPrefix}/claude "$@"
      '';
    };

    homebrew.casks = [ "claude-code" ];
  };
}
