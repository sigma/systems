# Work scopes helper
#
# Generates git conditional includes, jujutsu scoped configs, and
# open-url browser profile routing for GitHub organizations.
#
# This is a plain function rather than a NixOS module because home-manager
# modules inside nix-darwin cannot provide new capabilities through either
# custom options or _module.args without hitting infinite recursion
# (_module.freeformType cycle).
{ lib, user }:
with lib;
{
  mkWorkScopes =
    {
      name,
      emailSuffix,
      githubOrgs,
      browserProfile ? null,
      extraJjSettings ? { },
    }:
    let
      email = builtins.head (builtins.filter (e: hasSuffix emailSuffix e) user.allEmails);
    in
    mkMerge [
      {
        programs.git.includes =
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
          map workOrg githubOrgs;

        programs.jujutsu.scopes.${name} = {
          repositories = map (org: "~/src/github.com/${org}") githubOrgs;
          settings = { user.email = email; } // extraJjSettings;
        };
      }

      (mkIf (browserProfile != null) {
        programs.open-url.urlProfiles = builtins.listToAttrs (
          map (org: {
            name = "https://github.com/${org}";
            value = browserProfile;
          }) githubOrgs
        );
      })
    ];
}
