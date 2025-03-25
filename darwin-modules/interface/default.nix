{
  imports = [
    ./hotkeys.nix
    ./services.nix
    ./trackpad.nix
  ];

  config.interface.hotkeys.disable = [
    32 # Mission Control
    34
    33 # Application windows
    35
    60 # Input Sources
    61
    79 # Move left a space
    80
    81 # Move right a space
    82
  ];

  config.interface.services.disable = [
    "com.apple.Terminal - Open man Page in Terminal - openManPage"
    "com.apple.Terminal - Search man Page Index in Terminal - searchManPages"
    "com.apple.Safari - Search With %WebSearchProvider@ - searchWithWebSearchProvider"
    "com.apple.ChineseTextConverterService - Convert Text from Simplified to Traditional Chinese - convertTextToTraditionalChinese"
    "com.apple.ChineseTextConverterService - Convert Text from Traditional to Simplified Chinese - convertTextToSimplifiedChinese"
  ];
}
