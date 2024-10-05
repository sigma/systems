{
  lib,
  machine,
  user,
  ...
}:
with lib; {
  programs.onepassword.enable = mkForce true;

  programs.karabiner = mkIf machine.features.laptop {
    # that's horrendous, but for whatever reason the M3 MBP isn't detected
    # properly by karabiner. That means I'll have to connect it only to
    # keyboards that are ignored (which fortunately is the case)
    internalKeyboard = mkForce {};
  };

  home-manager.users.${user.login}.programs.git = {
    # make sure to use the right email for work repos.
    includes = [
      {
        condition = "hasconfig:remote.*.url:git@github.com:oplabspbc/**";
        contents = {
          user.email = "${user.email}";
          commit.gpgsign = true;
        };
        contentSuffix = "oplabs";
      }
    ];
  };

  programs.aerospace.workspaces = mkBefore [
    {
      name = "W"; # Work
      display = "main";
    }
  ];
  programs.aerospace.windowRules = mkBefore [
    {
      appId = "com.google.Chrome";
      layout = "tiling";
      windowTitleRegexSubstring = ".*\\(OPLabs\\)$";
      workspace = "W";
    }
  ];
}
