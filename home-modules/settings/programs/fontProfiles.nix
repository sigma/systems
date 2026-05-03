{ config, ... }:
let
  f = config.programs.fontCatalog;
  codingFont = f.fira-code;
  systemFallbacks = [
    "Menlo"
    "Monaco"
    "Courier New"
  ];
  terminalFallbacks = [ f.sauce-code-pro-nerd ] ++ systemFallbacks;
  fontSize = 14;
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
    family = codingFont;
    fallbacks = systemFallbacks;
    size = fontSize;
    features = ligatureFeatures;
  };

  terminal = {
    family = codingFont;
    fallbacks = terminalFallbacks;
    size = fontSize;
    weight = 600;
    features = ligatureFeatures;
  };

  ui = {
    family = codingFont;
    fallbacks = systemFallbacks;
    size = fontSize;
  };
}
