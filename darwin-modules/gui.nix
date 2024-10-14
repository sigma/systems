{user, ...}: {
  system.defaults.dock = {
    autohide = true;
    orientation = "left";
    show-recents = false;
    mru-spaces = false;
    tilesize = 48;
    expose-group-by-app = true;

    persistent-apps = let
      userApp = name: "/Users/${user.login}/Applications/Local/${name}.app";
    in [
      "/Applications/Google Chrome.app"
      (userApp "WezTerm")
      "/Applications/Cursor.app"
      (userApp "Emacs")
      "/Applications/Spotify.app"
      "/Applications/Notion.app"
    ];

    persistent-others = [
      "/Users/${user.login}/Documents"
      "/Users/${user.login}/Downloads"
    ];
  };

  system.defaults.finder = {
    AppleShowAllExtensions = true;
    AppleShowAllFiles = true;
    FXEnableExtensionChangeWarning = false;
    FXPreferredViewStyle = "clmv";
    ShowPathbar = true;
    ShowStatusBar = true;
  };

  system.defaults.NSGlobalDomain = {
    AppleShowAllFiles = true;
    AppleInterfaceStyle = "Dark";
    AppleMetricUnits = 1;

    NSAutomaticCapitalizationEnabled = false;
    NSAutomaticDashSubstitutionEnabled = false;
    NSAutomaticInlinePredictionEnabled = false;
    NSAutomaticPeriodSubstitutionEnabled = false;
    NSAutomaticQuoteSubstitutionEnabled = false;
    NSAutomaticSpellingCorrectionEnabled = true;
    NSAutomaticWindowAnimationsEnabled = false;
  };
}
