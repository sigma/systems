{
  lib,
  pkgs,
  user,
  machine,
  ...
}:
with lib;
{
  config = mkIf machine.features.firefly {
    user =
      let
        workGithubOrgs = [
          "firefly-engineering"
        ];
        email = builtins.head (builtins.filter (e: lib.hasSuffix "@firefly.engineering" e) user.allEmails);
      in
      {
        programs.git = {
          # make sure to use the right email for work repos.
          includes =
            let
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

        programs.jujutsu = {
          scopes.firefly = {
            repositories = map (org: "~/src/github.com/${org}") workGithubOrgs;

            settings = {
              user.email = email;

              remotes.origin = {
                auto-track-bookmarks = "glob:*";
              };
            };
          };
        };

        programs.gcloud = {
          enable = true;
          # need the most recent version of the SDK
          basePackage = pkgs.master.google-cloud-sdk;
          extraComponents =
            components: with components; [
              app-engine-go
              app-engine-python
              app-engine-python-extras
              cloud-run-proxy
              docker-credential-gcr
              gke-gcloud-auth-plugin
              log-streaming
              terraform-tools
            ];
        };

        home.packages = with pkgs; [
          terraform
          kubie
        ];
      };

    programs.aerospace.workspaces = mkBefore [
      {
        name = "P"; # Projects
        display = "main";
      }
    ];
    programs.aerospace.windowRules = mkBefore [
      {
        appId = "com.linear";
        layout = "tiling";
        workspace = "P";
      }
    ];

    homebrew.casks = [
      "claude-code"
      "linear-linear"
      "notion"
      "notion-calendar"
      "slack"
    ];
  };
}
