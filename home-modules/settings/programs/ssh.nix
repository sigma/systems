{
  lib,
  machine,
  ...
}:
let
  # Render a resolved remote (see CONTEXT.md) into its ssh_config match block.
  # Topology resolution already computed hostname / muxAddress / needsForcedTTY;
  # here we only turn those facts into ssh_config syntax.
  remoteBlock = r: {
    name = r.name;
    value = {
      sendEnv = [ "WINDOW" ];
    }
    // lib.optionalAttrs (r.hostname != null) { inherit (r) hostname; }
    // lib.optionalAttrs (r.user != null) { inherit (r) user; }
    // lib.optionalAttrs (r.sshOpts != null) (
      # Force a TTY on NixOS remotes (fish hangs on `ssh -T`); merge with any
      # extraOptions the host already supplies. See
      # docs/adr/0001-nixos-remote-forced-tty-and-mux.md.
      if r.needsForcedTTY && r.sshOpts ? extraOptions then
        r.sshOpts
        // {
          extraOptions = r.sshOpts.extraOptions // {
            RequestTTY = "force";
          };
        }
      else
        r.sshOpts
    )
    // lib.optionalAttrs (r.needsForcedTTY && (r.sshOpts == null || !(r.sshOpts ? extraOptions))) {
      extraOptions = {
        RequestTTY = "force";
      };
    };
  };

  # The `-mux` alias a NixOS remote needs so WezTerm's multiplexer can bypass the
  # forced TTY (which breaks its mux protocol). Keyed by the resolved muxAddress —
  # the one place the `-mux` string is authored is topology.nix.
  muxBlock =
    r:
    lib.optionalAttrs r.needsForcedTTY {
      ${r.muxAddress} = {
        inherit (r) hostname;
      };
    };

  # A stable `devbox` alias pointing at whichever remote is the devbox.
  devboxRemote = lib.findFirst (
    r: r.alias != null && lib.hasSuffix "-devbox" r.alias
  ) null machine.remotes;
  devboxAlias = lib.optionalAttrs (devboxRemote != null) {
    devbox = {
      hostname = devboxRemote.name;
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

  matchBlocks = {
    "*" = {
      compression = true;

      controlMaster = "auto";
      controlPath = "~/.ssh/ctrl-%C";
      controlPersist = "yes";

      serverAliveInterval = 30;
      serverAliveCountMax = 3;
    };
  }
  // remoteBlocks;
}
