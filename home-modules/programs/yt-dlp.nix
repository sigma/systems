{
  config,
  lib,
  pkgs,
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

  config = lib.mkMerge [
    {
      programs.yt-dlp = {
        enable = lib.mkDefault (config.features.media.enable);
        package = pkgs.master.yt-dlp;

        settings = {
          audio-quality = 0;
          embed-thumbnail = true;
          extractor-retries = 10;
          mtime = false;
        };

        homes =
          let
            download-archive = "downloaded.txt";
          in
          [
            {
              root = "Music";
              settings = {
                inherit download-archive;
                extract-audio = true;
                extractor-args = "soundcloud:formats=http_mp3";
                output = "%(extractor_key)s/%(artist)s - %(title)s.%(ext)s";
                preset-alias = [
                  "mp3"
                  "sleep"
                ];
                retry-sleep = [
                  "linear=1::2"
                  "fragment:exp=1:20"
                  "extractor:300"
                ];
              };
            }
            {
              root = "Video/Udemy";
              settings = {
                inherit download-archive;
                output = "%(playlist)s/%(chapter_number)s - %(chapter)s/%(playlist_index)s - %(title)s.%(ext)s";
                merge-output-format = "mp4";
                add-header = "Origin: https://www.udemy.com";
                concurrent-fragments = "16";
                format = "bestvideo+bestaudio/best";
              };
            }
            {
              root = "Video/YouTube";
              settings = {
                inherit download-archive;
                output = "%(playlist)s/%(title)s.%(ext)s";
                preset-alias = [
                  "mp4"
                  "sleep"
                ];
                retry-sleep = [
                  "linear=1::2"
                  "fragment:exp=1:20"
                  "extractor:300"
                ];
              };
            }
          ];
      };
    }

    (mkIf cfg.enable {
      home.file = builtins.listToAttrs (
        builtins.map (value: {
          name = "${value.root}/yt-dlp.conf";
          value = {
            text = concatStringsSep "\n" (remove "" (renderSettings value.settings)) + "\n";
          };
        }) cfg.homes
      );
    })
  ];
}
