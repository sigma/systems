{
  lib,
  pkgs,
  machine,
  user,
  ...
}:
with lib; {
  features.ipfs.enable = mkForce false;

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
    # this is for meet.google.com PIP mode
    {
      appId = "com.google.Chrome";
      windowTitleRegexSubstring = "^about:blank.*\\(SubZero\\)$";
      layout = "floating";
    }
    {
      appId = "com.google.Chrome";
      layout = "tiling";
      windowTitleRegexSubstring = ".*\\(SubZero\\)$";
      workspace = "W";
    }
    {
      appId = "com.brave.Browser";
      layout = "tiling";
      windowTitleRegexSubstring = ".*- Work$";
      workspace = "W";
    }
  ];

  home-manager.users.${user.login} = let
    workGithubOrgs = [
      "subzerolabs"
    ];
    email = builtins.head (builtins.filter (e: lib.hasSuffix "@subzero.xyz" e) user.allEmails);
  in {
    home.packages = with pkgs; [
      terraform
      kubie
      kubectl
    ];

    programs.open-url = {
      urlProfiles = builtins.listToAttrs (map (org: {
          name = "https://github.com/${org}";
          value = "Work";
        })
        workGithubOrgs);
    };

    programs.git = {
      # make sure to use the right email for work repos.
      includes = let
        workOrg = org: {
          condition = "hasconfig:remote.*.url:git@github.com:${org}/**";
          contents = {
            user.email = "${email}";
            commit.gpgsign = true;
          };
          contentSuffix = org;
        };
      in
        map workOrg workGithubOrgs;
    };
  };

  homebrew.brews = [
    "pkg-config"
    "openssl"
  ];
}
