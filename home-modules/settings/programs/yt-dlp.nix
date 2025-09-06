{...}: let
  downloadRoot = "~/Music";
in {
  enable = true;

  settings = {
    audio-quality = 0;
    download-archive = "'${downloadRoot}/downloaded.txt'";
    embed-thumbnail = true;
    extract-audio = true;
    extractor-args = "'soundcloud:formats=http_mp3'";
    extractor-retries = 10;
    mtime = false;
    output = "'${downloadRoot}/%(extractor_key)s/%(artist)s - %(title)s.%(ext)s'";
  };

  extraConfig = ''
    -t mp3
    -t sleep
    --retry-sleep linear=1::2
    --retry-sleep fragment:exp=1:20
    --retry-sleep extractor:300
  '';
}
