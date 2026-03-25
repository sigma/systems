{
  lib,
  pkgs,
  user,
  machine,
  ...
}:
with lib;
let
  inherit (import ./lib.nix { inherit lib user; }) mkWorkScopes;
in
{
  config = mkIf machine.features.firefly (
    mkMerge [
      (mkWorkScopes {
        name = "firefly";
        emailSuffix = "@firefly.engineering";
        githubOrgs = [
          "firefly-engineering"
        ];
      })

      {
        programs.jujutsu.scopes.firefly.settings = {
          remotes.origin.auto-track-bookmarks = "glob:*";
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

        programs.claude-firefly.enable = true;
        programs.claude-glm.enable = true;
        programs.opencode-firefly.enable = true;

        home.packages = with pkgs; [
          terraform
          kubie
        ];
      }
    ]
  );
}
