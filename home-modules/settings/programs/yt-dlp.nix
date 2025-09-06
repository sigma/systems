{...}: {
  enable = true;

  settings = {
    audio-quality = 0;
    cookies-from-browser = "brave";
    download-archive = "'~/Music/downloaded.txt'";
    embed-thumbnail = true;
    extract-audio = true;
    extractor-args = "'soundcloud:formats=http_mp3'";
    extractor-retries = 10;
    mtime = false;
    output = "'~/Music/%(extractor_key)s/%(artist)s - %(title)s.%(ext)s'";
  };

  extraConfig = ''
    -t mp3
    -t sleep
    --retry-sleep linear=1::2
    --retry-sleep fragment:exp=1:20
    --retry-sleep extractor:300
  '';
}
