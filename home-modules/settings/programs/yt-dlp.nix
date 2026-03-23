{ pkgs, ... }:
{
  enable = true;
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
}
