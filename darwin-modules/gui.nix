{ user, config, ... }:
let
  homeDir = config.users.users.${user.login}.home;
  userDir = name: "${homeDir}/${name}";
  userApp = name: "${homeDir}/Applications/Local/${name}.app";
  systemApp = name: "/Applications/${name}.app";
in
{
  system.defaults.dock = {
    autohide = true;
    orientation = "left";
    show-recents = false;
    mru-spaces = false;
    tilesize = 48;
    expose-group-apps = true;

    persistent-apps = [
      (systemApp "Google Chrome")
      (systemApp "Brave Browser")
      (userApp "WezTerm")
      (systemApp "Antigravity")
      (userApp "Emacs")
      (systemApp "Notion")
      (systemApp "Slack")
      (systemApp "Linear")
    ];

    persistent-others = [
      (userDir "Documents")
      (userDir "Downloads")
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
