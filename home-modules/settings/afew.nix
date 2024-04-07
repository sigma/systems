{
  ...
}: {
  enable = true;
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
