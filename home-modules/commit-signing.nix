# Commit signing identity, shared by git and jj.
#
# Both tools sign through `ssh-keygen -Y sign`, so they want the same two
# answers: which key signs, and which keys are trusted when verifying. This
# module computes both from the host roster; the git settings file and the jj
# module read them and never re-derive a key themselves.
#
# `ssh-keygen -Y sign` takes either a private key *file*, which it reads
# directly, or a public key *literal*, which it can only sign with by asking an
# ssh-agent for the private half. Hosts that hold the private key on disk
# therefore set `signingKeyFile` and sign agentlessly; hosts whose key lives in
# hardware leave it null and depend on an agent.
{
  config,
  lib,
  pkgs,
  machine,
  nixConfig,
  user,
  ...
}:
let
  expandHome =
    p: if lib.hasPrefix "~/" p then "${config.home.homeDirectory}/${lib.removePrefix "~/" p}" else p;

  # Every signing key this user owns is trusted under every address they commit
  # under, so a commit made on one host verifies on all the others regardless of
  # which email the repo-local policy selected.
  #
  # The principal order is cosmetic, not a match rule: git resolves a signature
  # with `ssh-keygen -Y find-principals`, which looks up by *key* and returns
  # every principal sharing the line, and git then displays the first. So
  # `--show-signature` names the first email here whichever address actually
  # authored the commit.
  principals = lib.concatStringsSep "," user.allEmails;
  allowedSigners = lib.concatMapStrings (key: "${principals} ${key}\n") (
    lib.attrValues (nixConfig.signingKeys or { })
  );
in
{
  options.programs.commitSigning = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = machine.signingKey != null;
      defaultText = lib.literalExpression "machine.signingKey != null";
      description = "Whether this host can sign commits, in git and in jj alike.";
    };

    key = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default =
        if machine.signingKeyFile != null then expandHome machine.signingKeyFile else machine.signingKey;
      defaultText = lib.literalExpression "the host's signingKeyFile if it has one, else its signingKey";
      description = ''
        What to hand `ssh-keygen -Y sign -f`: an absolute path to the private
        key, or a public key literal (which requires an ssh-agent).
      '';
    };

    allowedSignersFile = lib.mkOption {
      type = lib.types.str;
      default = "${pkgs.writeText "allowed-signers" allowedSigners}";
      defaultText = lib.literalExpression "generated from nixConfig.signingKeys";
      description = ''
        allowed-signers file used to verify signatures. Public keys only, so the
        nix store is a fine home for it.
      '';
    };
  };
}
