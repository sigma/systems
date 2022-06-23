{ config, lib, pkgs, machine, ... }:

let
  codeserverPort = 49363;
in
{
  enable = true;

  compression = true;

  controlMaster = "auto";
  controlPath = "~/.ssh/ctrl-%C";
  controlPersist = "yes";

  serverAliveInterval = 30;
  serverAliveCountMax = 3;
} // lib.optionalAttrs (builtins.hasAttr "sshMatchBlocks" machine) {
  matchBlocks = machine.sshMatchBlocks;
}

  # matchBlocks = {
  #   pdev = {
  #     hostname = "140.238.216.207";
  #     user = "ubuntu";
  #     forwardAgent = true;
  #     localForwards = [
  #       {
  #         bind.port = 2375;
  #         host.address = "/var/run/docker.sock";
  #       }
  #     ];
  #   };

  #   cdev = {
  #     hostname = "ghost-wheel.c.googlers.com";
  #     localForwards = [
  #       {
  #         bind.port = 2375;
  #         host.address = "/var/run/docker.sock";
  #       }
  #       {
  #         bind.port = codeserverPort;
  #         host.address = "localhost";
  #         host.port = codeserverPort;
  #       }
  #     ];
  #   };

# Host dev
#     Hostname shirka.c.googlers.com
#     ServeraliveInterval 30
#     ServerAliveCountMax 3
#     SendEnv WINDOW
#     LocalForward localhost:2375 /var/run/docker.sock
#     LocalForward 49363 localhost:49363
#     Compression yes

# Host cs
#     ProxyCommand /Users/yhodique/bin/cloudshell_proxy.sh
#     IdentitiesOnly yes
#     IdentityFile ~/.ssh/google_compute_engine
#     User yhodique
#     RequestTTY yes
#     RemoteCommand /usr/bin/env DEVSHELL_PROJECT_ID=google.com:yhodique-experiments bash -l
#     UserKnownHostsFile /dev/null
#     StrictHostKeyChecking no

# Host csp
#     ProxyCommand /Users/yhodique/bin/cloudshell_proxy.sh perso
#     IdentitiesOnly yes
#     IdentityFile ~/.ssh/google_compute_engine
#     User yann_hodique
#     RequestTTY yes
#     RemoteCommand /usr/bin/env DEVSHELL_PROJECT_ID=personal-projects-179500 bash -l
#     UserKnownHostsFile /dev/null
#     StrictHostKeyChecking no

  # };
