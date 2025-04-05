{
  lib,
  user,
  ...
}: {
  home-manager.users.${user.login} = let
    workGithubOrgs = [
      "firefly-engineering"
    ];
    email = builtins.head (builtins.filter (e: lib.hasSuffix "@firefly.engineering" e) user.allEmails);
  in {
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
}
