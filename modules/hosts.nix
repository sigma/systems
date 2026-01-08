{
  nebula.features = [
    "work" # generic work feature
    "firefly" # specifically for firefly engineering
    "subzero" # specifically for subzero contracting
    "music" # music production
    "fusion" # for Fusion VMs
    "determinate" # for Determinate Nix
    "gaming" # for gaming
    "tailscale" # for Tailscale VPN
  ];

  nebula.sharedDomain = "van-scylla.ts.net";

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
        alias = "spectre";
        system = "aarch64-darwin";
        remotes = [
          pdev
          csp
          spectre-devbox
          shirka
        ];
        features = [
          "determinate"
          "managed"
          "mac"
          "music"
          "firefly"
          "gaming"
          "tailscale"
        ];
        u2fKeys = portableU2fKeys ++ [
          # desktop titan
          "7fZp73vnETk6Nen9OqNu49XEnQvlpqIIYYeNJDM4p/w1DprKpyqw8kvRCalbqMNwfLaElmbhHYKN4nKvMvoTPg==,yxC16UIBA7Ajkr/2uVVGx5DUCPLJOEYXHi8bs0KrTlFSL4SH+eF9rChm6V13jcldqSfL/d66REtrbRYqg5/0xQ==,es256,+presence"
        ];
        builder = {
          enable = true;
          maxJobs = 8;
          speedFactor = 10;
          sshUser = "yann";
          supportedFeatures = [ "big-parallel" ];
          sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICOFQODLDegQzo1pEDrnzP6GJwmSudZ270EeXzsSr2d3 spectre-builder";
          storePublicKey = "spectre-builder:jBwyDL6nsUSwyNgy6iNYCZD0pDiXfqD0xvy3Avxib20=";
        };
      };

      ash = {
        name = "ash.local";
        alias = "ash";
        system = "aarch64-darwin";
        remotes = [
          pdev
          csp
          ash-devbox
          shirka
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
          "tailscale"
        ];
        u2fKeys = portableU2fKeys ++ [
          # home dock yubikey
          "QKdeeNCt3nfvAUwc2bx4A/Lamg+dtCdU5Mdsq+L+GxBkbr0eO6oWsVwE7NmzMMVhbljYDs3CDwh34zWem9pqwQ==,NYMKNF72hkXSTZCWU4sQXdy0oGbmT6B0WSuuEabso5YzRM//ZU5EEOr9TJBP64tc6mliCAIBFBdoQPi6Mcdw0g==,es256,+presence"
          # laptop low-profile key
          "mEJg6bvtXfOO8r3USlUbN6xaW87kBR7xAlVTfeFxdQSAh06vNXqOLgbjQu4XHbM1qdmEQNlfhrErxfR6Jv5M8A==,iiS2fAX/OMD79/nSPRtG/OPVn326dvU/qV2EkxAfVvasuE2I98odrFgGA3IRJyBF8ucC+sEMt/uVekIs01uqhA==,es256,+presence"
        ];
        signingKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBCH9S6aF3W4/pKY+s/FpZAl8zIXXxI7LHE4fVd+foYdXtQI2mhiIyBX4jtbYkhACOSha5i2TPYKpBqy3NtI/utc=";
        builder = {
          enable = true;
          maxJobs = 8;
          speedFactor = 10;
          sshUser = "yann";
          supportedFeatures = [ "big-parallel" ];
          sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJXjN5tmhFNXn0VC06tPgWLRYOEMqrNnS38fjHe+ClOc ash-builder";
          storePublicKey = "ash-builder:dzF0FVd4nvgsJE5NUybyngj9UXyF8FS+zjdsPPpPatM=";
        };
      };

      shirka = {
        name = "192.168.1.157";
        alias = "shirka";
        system = "x86_64-linux";
        remotes = [
          pdev
          csp
          ash-devbox
          spectre-devbox
        ];
        features = [
          "managed"
          "nixos"
          "interactive"
          "work"
          "firefly"
          "tailscale"
        ];
        enableSwap = false;
        bootLabel = "boot";
        builder = {
          enable = true;
          maxJobs = 4;
          speedFactor = 10;
          sshUser = "nixbuilder";
          supportedFeatures = [
            "nixos-test"
            "big-parallel"
            "kvm"
          ];
          sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA6RaKDYN9eLKKmk2M7y+m5HBQ3WI0h8Y/FgNR9i9P7v shirka-builder";
          storePublicKey = "shirka-builder:ljFu1tbLM+lH2DNlKfGRZJyrdrWNnTlbKC82qQFJB8g=";
        };
      };

      ash-devbox = {
        name = "192.168.1.82";
        alias = "ash-devbox";
        system = "aarch64-linux";
        remotes = [
          shirka
        ];
        features = [
          "managed"
          "fusion"
          "nixos"
          "work"
          "subzero"
          "tailscale"
        ];
        sshOpts = {
          forwardAgent = true;
          extraOptions = {
            AddKeysToAgent = "yes";
          };
        };
        bootLabel = "boot";
        builder = {
          enable = true;
          maxJobs = 4;
          speedFactor = 10;
          sshUser = "nixbuilder";
          supportedFeatures = [
            "nixos-test"
            "big-parallel"
          ];
          sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBu5UCinocrjwfRvjBhrjB7pQJFqdCNDpd6IC0NMkiq7 ash-devbox-builder";
          storePublicKey = "ash-devbox-builder:I0IgbNp3CBOF/4shE3EePUpcvokEQguuTyTbYfo3Bjc=";
        };
      };

      spectre-devbox = {
        name = "192.168.1.73";
        alias = "spectre-devbox";
        system = "aarch64-linux";
        remotes = [
          shirka
        ];
        features = [
          "managed"
          "fusion"
          "nixos"
          "work"
          "tailscale"
        ];
        sshOpts = {
          forwardAgent = true;
          extraOptions = {
            AddKeysToAgent = "yes";
          };
        };
        bootLabel = "boot";
        enableSwap = false;
        builder = {
          enable = true;
          maxJobs = 4;
          speedFactor = 10;
          sshUser = "nixbuilder";
          supportedFeatures = [
            "nixos-test"
            "big-parallel"
          ];
          sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBUh7zw1mlXTTeT9S3EMTrMEdQ1LMUYgDEqhaurbfaYP spectre-devbox-builder";
          storePublicKey = "spectre-devbox-builder:AcPGiyR/CKrwZ+/f7IvbDqKARmyNRf10XqgmtWrGNMQ=";
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
