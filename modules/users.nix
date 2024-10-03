{config, ...}: let
  cfg = config.nebula;
in {
  nebula.users = let
    name = "Yann Hodique";
    githubHandle = "sigma";
    googleProfile = {
      name = "work";
      emails = ["yhodique@google.com" "yrh@google.com"];
    };
    persoProfile = {
      name = "perso";
      emails = ["yann.hodique@gmail.com" "yann@hodique.info"];
    };
    oplabsProfile = {
      name = "oplabs";
      emails = ["yann@oplabs.co"];
    };
  in {
    personalUser = {
      inherit name githubHandle;
      login = "yann";
      profiles = [
        persoProfile
      ];
    };

    googleUser = {
      inherit name githubHandle;
      login = "yhodique";
      profiles = [
        googleProfile
        persoProfile
      ];
    };

    oplabsUser = {
      inherit name githubHandle;
      login = "yann";
      profiles = [
        oplabsProfile
        persoProfile
      ];
    };
  };

  nebula.userSelector = machine:
    if machine.features.work
    then
      (
        if machine.features.google
        then cfg.users.googleUser
        else cfg.users.oplabsUser
      )
    else cfg.users.personalUser;
}
