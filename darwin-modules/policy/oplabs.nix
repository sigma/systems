{
  lib,
  pkgs,
  machine,
  user,
  ...
}:
with lib; {
  programs.kurtosis.enable = mkForce true;

  programs.onepassword.enable = mkForce true;

  programs.karabiner = mkIf machine.features.laptop {
    # that's horrendous, but for whatever reason the M3 MBP isn't detected
    # properly by karabiner. That means I'll have to connect it only to
    # keyboards that are ignored (which fortunately is the case)
    internalKeyboard = mkForce {};
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

  home-manager.users.${user.login} = {
    programs.gcloud.enable = mkForce true;
    programs.gcloud.enableGkeAuthPlugin = mkForce true;

    home.packages = with pkgs; [
      terraform
      kubie
      kubectl
    ];

    programs.git = {
      # make sure to use the right email for work repos.
      includes = [
        {
          condition = "hasconfig:remote.*.url:git@github.com:ethereum-optimism/**";
          contents = {
            user.email = "${user.email}";
            commit.gpgsign = true;
          };
          contentSuffix = "oplabs";
        }
      ];
    };
  };
}
