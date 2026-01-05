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
     {
        name = "yann-spectre-devbox-ssh";
        type = "ssh";
        publicKey = "age1a4zrf52jlfrnwkywwsxwmsl5cvj43qp0qp0d66zymx86pr5jgdmqh0sxge";
      }
      {
        name = "yann-shirka-ssh";
        type = "ssh";
        publicKey = "age1jm3mx2eqxacwq4hlw4euw05u37a4w89tp2yj2nk8xc3ukv3x93fslslta9";
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

        # Builder SSH private keys (for connecting TO each builder)
        "builder-keys/ash" = systemSecret;
        "builder-keys/spectre" = systemSecret;
        "builder-keys/shirka" = systemSecret;
        "builder-keys/ash-devbox" = systemSecret;
        "builder-keys/spectre-devbox" = systemSecret;

        # Store signing private keys (for each machine to sign its store)
        "store-keys/ash" = systemSecret;
        "store-keys/spectre" = systemSecret;
        "store-keys/shirka" = systemSecret;
        "store-keys/ash-devbox" = systemSecret;
        "store-keys/spectre-devbox" = systemSecret;
      };
  };
}
