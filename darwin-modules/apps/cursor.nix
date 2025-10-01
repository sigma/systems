{
  config,
  lib,
  user,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.cursor;
in
{
  options.programs.cursor = {
    enable = mkEnableOption "cursor";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.login}.programs.cursor = {
      enable = true;
      # create a symlink to the actual Cursor application
      package = pkgs.stdenv.mkDerivation {
        pname = "cursor";
        version = "1.74.0";
        src = null;
        buildCommand = ''
          mkdir -p $out/bin
          ln -sf ${config.homebrew.brewPrefix}/cursor $out/bin/cursor
        '';

        meta = with lib; {
          maintainers = [ sigma ];
          mainProgram = "cursor";
        };
      };
    };

    homebrew.casks = [ "cursor" ];
  };
}
