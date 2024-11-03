{config, ...}: let
  cfg = config.nebula;
in {
  nebula.users = let
    name = "Yann Hodique";
    login = "yann";
    githubHandle = "sigma";
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
      inherit name githubHandle login;
      profiles = [
        persoProfile
      ];
    };

    oplabsUser = {
      inherit name githubHandle login;
      profiles = [
        oplabsProfile
        persoProfile
      ];
    };
  };

  nebula.userSelector = machine:
    if machine.features.work
    then cfg.users.oplabsUser
    else cfg.users.personalUser;
}
