{
  config,
  machine,
  ...
}:
{
  enable = config.features.media.enable;
  musicPath = "~/Music";
  theme = "catpuccin";
  settings.colorMode = 2;
}
