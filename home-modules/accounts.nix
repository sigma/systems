{user, ...}: {
  accounts.email.maildirBasePath = ".mail";
  accounts.email.accounts.${user.login} = {
    primary = true;
    notmuch.enable = true;
    realName = user.name;
    address = user.email;
    aliases = user.aliases;
  };
}
