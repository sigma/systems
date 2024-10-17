{
  lib,
  pkgs,
  user,
  ...
}:
with lib; {
  # those files are handled by corp and will be reverted anyway, so
  # skip the warning about them being overwritten.
  environment.etc = {
    "shells".knownSha256Hashes = [
      # default MacOS content. This is safe to override
      "9d5aa72f807091b481820d12e693093293ba33c73854909ad7b0fb192c2db193"
    ];
    "zshrc".knownSha256Hashes = [
      "7055352423251faa46af6bb3b1754b0119558f5460c4b49d27189a9cac794bc3"
      "0c65e335c154a6b4a88f635c7b2aee8c6f49bd48ee522fd3685f75e2686b6af3"
    ];
    # leave bashrc alone, I don't use bash
    "bashrc".enable = false;
  };

  environment.systemPackages = [
    pkgs.gitGoogle
  ];
  home-manager.users.${user.login}.programs.git = {
    package = pkgs.gitGoogle;

    # Make sure to use the right email for google internal repos and k8s ones.
    # Also make sure to sign k8s commits
    includes = [
      {
        condition = "hasconfig:remote.*.url:sso://**";
        contents = {
          user.email = "${user.email}";
        };
        contentSuffix = "gob";
      }
      {
        condition = "hasconfig:remote.*.url:git@github.com:kubernetes/**";
        contents = {
          user.email = "${user.email}";
          commit.gpgsign = true;
        };
        contentSuffix = "k8s";
      }
    ];
  };

  # The following are disallowed on corp machines
  programs.tailscale.enable = mkForce false;
  services.tailscale.enable = mkForce false;
  security.pam.enableSudoTouchIdAuth = mkForce false;
  security.pam.enableReattachedSudoTouchIdAuth = mkForce false;
  programs.orbstack.enable = mkForce false;
  # allow secretive, but don't interfere with gnubby auth
  programs.secretive.globalAgentIntegration = mkForce false;
  programs.secretive.zshIntegration = mkForce false;

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
      windowTitleRegexSubstring = ".*\\(Google\\)$";
      workspace = "W";
    }
  ];
}
