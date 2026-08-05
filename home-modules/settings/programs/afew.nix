{ config, ... }:
{
  # afew pulls in notmuch, which has no aarch64-darwin binary cache and takes
  # very long to build from source. Only enable it where mail is actually set
  # up, matching programs.notmuch.
  inherit (config.programs.mailsetup) enable;
  # This config is designed to work with --all
  extraConfig = ''
    [NewKillThreadsFilter]

    [NewArchiveSentMailsFilter]

    [ExpireFilter]
    tag = cls
    after = 259200minutes

    [Filter.0]
    query = tag:new
    tags = -new
    message = making new messages old
  '';
}
