let
  name = "Yann Hodique";
  workProfile = {
    name = "work";
    emails = ["yhodique@google.com" "yrh@google.com"];
  };
  persoProfile = {
    name = "perso";
    emails = ["yann.hodique@gmail.com" "yann@hodique.info"];
  };

  expandUser = user: user // rec {
    allEmails = builtins.concatMap (prof: prof.emails) user.profiles;
    email = builtins.head allEmails;
    aliases = builtins.tail allEmails;
  };
in
{
  corpUser = expandUser {
    inherit name;
    login = "yhodique";
    profiles = [
      workProfile
      persoProfile
    ];
  };

  personalUser = expandUser {
    inherit name;
    login = "yann";
    profiles = [
      persoProfile
    ];
  };
}
