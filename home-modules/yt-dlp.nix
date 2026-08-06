{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.yt-dlp;
  renderSetting =
    name: value:
    if lib.isBool value then
      if value then "--${name}" else "--no-${name}"
    else
      let
        strValue = toString value;
        isQuoted =
          hasPrefix "\"" strValue
          || hasPrefix "'" strValue
          || hasSuffix "\"" strValue
          || hasSuffix "'" strValue;
        quotedValue = if isQuoted then strValue else escapeShellArg strValue;
      in
      "--${name} ${quotedValue}";
  renderSettings =
    attrs:
    concatLists (
      mapAttrsToList (
        name: value: if isList value then map (renderSetting name) value else [ (renderSetting name value) ]
      ) attrs
    );

  valueType =
    with types;
    oneOf [
      bool
      int
      str
    ];
  homeModule = types.submodule {
    options = {
      root = mkOption {
        type = types.str;
        default = "";
      };

      settings = mkOption {
        type = types.attrsOf (types.either valueType (types.listOf valueType));
        default = { };
      };
    };
  };
in
{
  options.programs.yt-dlp = {
    homes = mkOption {
      type = types.listOf homeModule;
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    home.file = builtins.listToAttrs (
      builtins.map (value: {
        name = "${value.root}/yt-dlp.conf";
        value = {
          text = concatStringsSep "\n" (remove "" (renderSettings value.settings)) + "\n";
        };
      }) cfg.homes
    );
  };
}
