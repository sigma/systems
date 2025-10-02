{ config, user, ... }:
{
  accounts.email.maildirBasePath = ".mail";
  accounts.email.accounts.${user.login} = {
    primary = true;
    notmuch.enable = config.programs.notmuch.enable;
    realName = user.name;
    address = user.email;
    aliases = user.aliases;
  };
}
