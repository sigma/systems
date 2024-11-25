{
  nebula.features = ["work" "oplabs" "music" "fusion"];

  nebula.hosts = let
    cloudshellCmd = proj: "/usr/bin/env DEVSHELL_PROJECT_ID=${proj} bash -l";
  in rec {
    spectre = {
      name = "spectre.local";
      system = "aarch64-darwin";
      remotes = [pdev csp];
      features = ["managed" "mac" "music"];
    };

    ash = {
      name = "ash.local";
      system = "aarch64-darwin";
      remotes = [pdev csp devbox];
      features = ["managed" "laptop" "mac" "work" "oplabs" "music"];
    };

    devbox = {
      name = "192.168.77.131";
      system = "aarch64-linux";
      features = ["managed" "fusion" "nixos" "work" "oplabs"];
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
