{
  ...
}:
{
  # Default secrets configuration
  # Keys and structure ready, secrets file at secrets/secrets.yaml
  nebula.secrets = {
    enable = true;

    ageKeys = [
      {
        name = "yann-laptop-ssh";
        type = "ssh";
        publicKey = "age10zp04uauqx9nvan9jvvpyw82szm87mzugrsjar4p9h704vzml9ksg2me04";
      }
    ];

    sshKeyPaths = [ "~/.ssh/id_ed25519" ];

    defaultSopsFile = ../secrets/secrets.yaml;

    secrets =
      let
        systemSecret = { };
        userSecret = {
          owner = "@user";
        };
      in
      {
        github-key-uploader-pat = systemSecret;
        glm-api-key = userSecret;

        # Cachix auth tokens
        "cachix/sigma" = userSecret;
      };
  };
}
