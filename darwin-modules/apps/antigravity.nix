{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.antigravity;
in
{
  options.programs.antigravity = {
    enable = mkEnableOption "antigravity";
  };

  config = mkIf cfg.enable {
    user.programs.antigravity = {
      enable = true;
      # create a symlink to the actual Antigravity application
      package = pkgs.stdenv.mkDerivation {
        pname = "antigravity";
        version = "0.0.1"; # Placeholder version
        src = null;
        buildCommand = ''
          mkdir -p $out/bin
          # Assuming standard homebrew location for now
          ln -sf ${config.homebrew.brewPrefix}/antigravity $out/bin/antigravity
          ln -sf $out/bin/antigravity $out/bin/code

          # Create dummy product.json to satisfy Home Manager
          cat > $out/product.json <<EOF
          {
            "nameShort": "Antigravity",
            "nameLong": "Antigravity",
            "applicationName": "antigravity",
            "dataFolderName": ".antigravity",
            "serverDataFolderName": ".antigravity-server",
            "extensionsGallery": {
              "serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery",
              "cacheUrl": "https://vscode.blob.core.windows.net/gallery/index",
              "itemUrl": "https://marketplace.visualstudio.com/items"
            }
          }
          EOF
        '';

        meta = with lib; {
          maintainers = [ ];
          mainProgram = "antigravity";
        };
      };
    };

    homebrew.casks = [ "antigravity" ];
  };
}
