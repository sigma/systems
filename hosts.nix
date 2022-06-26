{ lib }:

let
  dockerPort = 2375;
  codeserverPort = 49363;

  sshHost = r: {
    name = if builtins.hasAttr "alias" r then r.alias else r.name;
    value = {
      sendEnv = ["WINDOW"];
    } // (lib.optionalAttrs (builtins.hasAttr "name" r) {
      hostname = r.name;
    }) // (lib.optionalAttrs (builtins.hasAttr "user" r) {
      user = r.user;
    }) // (lib.optionalAttrs (builtins.hasAttr "sshOpts" r) r.sshOpts);
  };
  sshBlocks = mac: if builtins.hasAttr "remotes" mac then
    builtins.listToAttrs (builtins.map sshHost mac.remotes) else {};

  cloudshellCmd = proj: "/usr/bin/env DEVSHELL_PROJECT_ID=${proj} bash -l";

  dockerFwd = {
    bind.port = dockerPort;
    host.address = "/var/run/docker.sock";
  };
  codeserverFwd = {
    bind.port = codeserverPort;
    host.address = "localhost";
    host.port = codeserverPort;
  };

  unmanaged = mac: mac // {
    isWork = false;
  };
  cloudshell = mac: mac // {
    system = "x86_64-linux";
    isWork = false;
  };
  cloudtop = mac: mac // {
    isWork = true;
    system = "x86_64-linux";
    sshMatchBlocks = sshBlocks mac;
  };
  gmac = mac: mac // {
    isWork = true;
    sshMatchBlocks = sshBlocks mac;
  };
in rec {
  cs = cloudshell {
    alias = "cs";
    user = "yhodique";
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

  csp = cloudshell {
    alias = "csp";
    profile = "perso";
    user = "yann_hodique";
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

  pdev = unmanaged {
    name = "140.238.216.207";
    alias = "pdev";
    system = "aarch64-linux";
    user = "ubuntu";
  };

  shirka = cloudtop {
    name = "shirka.c.googlers.com";
    alias = "dev";
    remotes = [pdev cs];
    sshOpts = {
      localForwards = [dockerFwd codeserverFwd];
    };
  };

  ghost-wheel = cloudtop {
    name = "ghost-wheel.c.googlers.com";
    alias = "cdev";
    remotes = [pdev cs];
    sshOpts = {
      localForwards = [dockerFwd codeserverFwd];
    };
  };

  yhodique-macbookpro = gmac {
    name = "yhodique-macbookpro.roam.internal";
    system = "aarch64-darwin";
    remotes = [ghost-wheel shirka pdev cs csp];
  };

  yhodique-macmini = gmac {
    name = "yhodique-macmini.roam.corp.google.com";
    system = "x86_64-darwin";
    remotes = [ghost-wheel shirka pdev cs csp];
  };
}
