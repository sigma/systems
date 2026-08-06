{
  machine,
  user,
  ...
}:
{
  security.pam.u2f.enable = true;

  security.pam.u2f.authorizations = map (key: "${user.login}:${key}") machine.u2fKeys;

  homebrew.brews = [
    "openssh" # for FIDO2 support
  ];
}
