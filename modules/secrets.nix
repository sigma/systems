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
      {
        name = "yann-devbox-ssh";
        type = "ssh";
        publicKey = "age1ae6hr009lp657dhjlcufrfx6cu7vy3h0alxmns3uj5pr3xq4zydsp3kht6";
      }
      {
        name = "yann-spectre-ssh";
        type = "ssh";
        publicKey = "age1r02uvfeluscppkrh2me46egs99zcaal5swdlmhcyh0eqj0m2d4ssx97vuz";
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
