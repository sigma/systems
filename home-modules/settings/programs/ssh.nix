{
  lib,
  machine,
  ...
}:
let
  # Render a resolved remote (see CONTEXT.md) into its ssh_config block.
  # Topology resolution already computed hostname / muxAddress / needsForcedTTY;
  # here we only turn those facts into ssh_config syntax. Keys are upstream
  # OpenSSH directive names, which is what `programs.ssh.settings` expects.
  remoteBlock = r: {
    name = r.name;
    value = {
      SendEnv = [ "WINDOW" ];
    }
    // lib.optionalAttrs (r.hostname != null) { HostName = r.hostname; }
    // lib.optionalAttrs (r.user != null) { User = r.user; }
    // lib.optionalAttrs (r.sshOpts != null) r.sshOpts
    # Force a TTY on NixOS remotes (fish hangs on `ssh -T`); overrides any
    # RequestTTY the host itself declares. See
    # docs/adr/0001-nixos-remote-forced-tty-and-mux.md.
    // lib.optionalAttrs r.needsForcedTTY { RequestTTY = "force"; };
  };

  # The `-mux` alias a NixOS remote needs so WezTerm's multiplexer can bypass the
  # forced TTY (which breaks its mux protocol). Keyed by the resolved muxAddress —
  # the one place the `-mux` string is authored is topology.nix.
  muxBlock =
    r:
    lib.optionalAttrs r.needsForcedTTY {
      ${r.muxAddress} = {
        HostName = r.hostname;
      };
    };

  # A stable `devbox` alias pointing at whichever remote is the devbox.
  devboxRemote = lib.findFirst (
    r: r.alias != null && lib.hasSuffix "-devbox" r.alias
  ) null machine.remotes;
  devboxAlias = lib.optionalAttrs (devboxRemote != null) {
    devbox = {
      HostName = devboxRemote.name;
    };
  };

  remoteBlocks =
    builtins.listToAttrs (map remoteBlock machine.remotes)
    // lib.foldl' (acc: r: acc // muxBlock r) { } machine.remotes
    // devboxAlias;
in
{
  enable = true;
  enableDefaultConfig = false;

  settings = {
    "*" = {
      Compression = true;

      ControlMaster = "auto";
      ControlPath = "~/.ssh/ctrl-%C";
      ControlPersist = "yes";

      ServerAliveInterval = 30;
      ServerAliveCountMax = 3;
    };
  }
  // remoteBlocks;
}
