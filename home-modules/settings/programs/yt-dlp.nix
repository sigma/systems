{...}: {
  enable = true;

  settings = {
    audio-quality = 0;
    embed-thumbnail = true;
    extractor-retries = 10;
    mtime = false;
  };

  homes = [
    {
      root = "Music";
      settings = {
        download-archive = "downloaded.txt";
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
        download-archive = "downloaded.txt";
        output = "%(playlist)s/%(chapter_number)s - %(chapter)s/%(title)s.%(ext)s";
      };
    }
  ];
}
