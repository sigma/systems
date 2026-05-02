{ config, ... }:
let
  f = config.programs.fontCatalog;
  systemFallbacks = [
    "Menlo"
    "Monaco"
    "Courier New"
    "monospace"
  ];
  ligatureFeatures = [
    "cv01"
    "cv02"
    "cv04"
    "cv16"
    "cv18"
    "cv29"
    "cv31"
    "ss01"
    "ss02"
    "ss03"
    "ss05"
  ];
in
{
  editor = {
    family = f.fira-code;
    fallbacks = systemFallbacks;
    size = 14;
    features = ligatureFeatures;
  };

  terminal = {
    family = f.fira-code;
    fallbacks = [ f.sauce-code-pro-nerd ] ++ systemFallbacks;
    size = 13;
    weight = 600;
    features = ligatureFeatures;
  };

  ui = {
    family = f.fira-code;
    fallbacks = systemFallbacks;
    size = 13;
  };
}
