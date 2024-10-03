{
  nebula.features = ["work" "google" "oplabs" "music"];

  nebula.hosts = let
    cloudshellCmd = proj: "/usr/bin/env DEVSHELL_PROJECT_ID=${proj} bash -l";
    glinuxHomeRoot = "/usr/local/google/home/";
  in rec {
    yhodique-macbookpro = {
      name = "yhodique-macbookpro.roam.internal";
      system = "aarch64-darwin";
      remotes = [shirka pdev cs csp];
      features = ["managed" "laptop" "mac" "work" "google"];
    };

    yhodique-macmini = {
      name = "yhodique-macmini.roam.corp.google.com";
      system = "x86_64-darwin";
      remotes = [shirka pdev cs csp];
      features = ["managed" "mac" "work" "google"];
    };

    shirka = {
      name = "shirka.c.googlers.com";
      alias = "dev";
      system = "x86_64-linux";
      homeRoot = glinuxHomeRoot;
      remotes = [pdev cs];
      features = ["managed" "linux" "work" "google"];
    };

    spectre = {
      name = "spectre.local";
      system = "aarch64-darwin";
      remotes = [pdev csp];
      features = ["managed" "mac" "music"];
    };

    ash = {
      name = "ash.local";
      system = "aarch64-darwin";
      remotes = [pdev csp];
      features = ["managed" "laptop" "mac" "work" "oplabs" "music"];
    };

    pdev = {
      name = "140.238.216.207";
      alias = "pdev";
      user = "ubuntu";
      system = "aarch64-linux";
    };

    cs = {
      alias = "cs";
      user = "yhodique";
      system = "x86_64-linux";
      sshOpts = {
        identitiesOnly = true;
        identityFile = "~/.ssh/google_compute_engine";
        proxyCommand = "~/.ssh/cloudshell_proxy default";
        extraOptions = {
          RemoteCommand = cloudshellCmd "google.com:yhodique-experiments";
          RequestTTY = "yes";
          StrictHostKeyChecking = "no";
          UserKnownHostsFile = "/dev/null";
        };
      };
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

    # anonymous profile, useful for dynamically created instances that
    #I can't be bothered to register here.
    glinux = {
      name = "glinux";
      system = "x86_64-linux";
      homeRoot = glinuxHomeRoot;
      features = ["managed" "linux" "work" "google"];
    };
  };
}
