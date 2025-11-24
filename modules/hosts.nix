{
  nebula.features = [
    "work" # generic work feature
    "firefly" # specifically for firefly engineering
    "subzero" # specifically for subzero contracting
    "music" # music production
    "fusion" # for Fusion VMs
    "determinate" # for Determinate Nix
    "gaming" # for gaming
  ];

  nebula.hosts =
    let
      cloudshellCmd = proj: "/usr/bin/env DEVSHELL_PROJECT_ID=${proj} bash -l";

      # Portable U2F keys used across multiple machines
      portableU2fKeys = [
        "sKyQL1tKpsjH1WsM+fZXysX4Cdff/N6FjS4G3SinILb5TZOF6JrFI4hdIYzmn+2kYXJru+DMHtSj/NRYrhDldA==,kP7KSC4S4Fqgei6HBZ/BFpS/Chun+4Kn6H0fZ2OyFEvq6y9jkqz+IWTrlk3XiU4DoBcdF/uj+Muofq/DTaQCMw==,es256,+presence"
      ];
    in
    rec {
      spectre = {
        name = "spectre.local";
        system = "aarch64-darwin";
        remotes = [
          pdev
          csp
        ];
        features = [
          "determinate"
          "managed"
          "mac"
          "music"
          "firefly"
          "gaming"
        ];
        u2fKeys = portableU2fKeys ++ [
          # desktop titan
          "7fZp73vnETk6Nen9OqNu49XEnQvlpqIIYYeNJDM4p/w1DprKpyqw8kvRCalbqMNwfLaElmbhHYKN4nKvMvoTPg==,yxC16UIBA7Ajkr/2uVVGx5DUCPLJOEYXHi8bs0KrTlFSL4SH+eF9rChm6V13jcldqSfL/d66REtrbRYqg5/0xQ==,es256,+presence"
        ];
      };

      ash = {
        name = "ash.local";
        system = "aarch64-darwin";
        remotes = [
          pdev
          csp
          devbox
        ];
        features = [
          "managed"
          "laptop"
          "mac"
          "work"
          "music"
          "firefly"
          "determinate"
          "subzero"
          "gaming"
        ];
        u2fKeys = portableU2fKeys ++ [
          # home dock yubikey
          "QKdeeNCt3nfvAUwc2bx4A/Lamg+dtCdU5Mdsq+L+GxBkbr0eO6oWsVwE7NmzMMVhbljYDs3CDwh34zWem9pqwQ==,NYMKNF72hkXSTZCWU4sQXdy0oGbmT6B0WSuuEabso5YzRM//ZU5EEOr9TJBP64tc6mliCAIBFBdoQPi6Mcdw0g==,es256,+presence"
          # laptop low-profile key
          "mEJg6bvtXfOO8r3USlUbN6xaW87kBR7xAlVTfeFxdQSAh06vNXqOLgbjQu4XHbM1qdmEQNlfhrErxfR6Jv5M8A==,iiS2fAX/OMD79/nSPRtG/OPVn326dvU/qV2EkxAfVvasuE2I98odrFgGA3IRJyBF8ucC+sEMt/uVekIs01uqhA==,es256,+presence"
        ];
        signingKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBCH9S6aF3W4/pKY+s/FpZAl8zIXXxI7LHE4fVd+foYdXtQI2mhiIyBX4jtbYkhACOSha5i2TPYKpBqy3NtI/utc=";
      };

      devbox = {
        name = "192.168.77.131";
        alias = "devbox";
        system = "aarch64-linux";
        features = [
          "managed"
          "fusion"
          "nixos"
          "work"
          "subzero"
        ];
        sshOpts = {
          forwardAgent = true;
          extraOptions = {
            AddKeysToAgent = "yes";
          };
        };
      };

      pdev = {
        name = "140.238.216.207";
        alias = "pdev";
        user = "ubuntu";
        system = "aarch64-linux";
      };

      csp = {
        alias = "csp";
        user = "yann_hodique";
        system = "x86_64-linux";
        sshOpts = {
          identitiesOnly = true;
          identityFile = "~/.ssh/google_compute_engine";
          proxyCommand = "~/.ssh/cloudshell_proxy perso";
          extraOptions = {
            RemoteCommand = cloudshellCmd "personal-projects-179500";
            RequestTTY = "yes";
            StrictHostKeyChecking = "no";
            UserKnownHostsFile = "/dev/null";
          };
        };
      };
    };
}
