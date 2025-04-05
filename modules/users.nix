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
    fireflyProfile = {
      name = "firefly";
      emails = ["yann@firefly.engineering"];
    };
    oplabsProfile = {
      name = "oplabs";
      emails = ["yann@oplabs.co"];
    };
  in {
    personalUser = {
      inherit name githubHandle login;
      profiles = [
        fireflyProfile
        persoProfile
      ];
    };

    workUser = {
      inherit name githubHandle login;
      profiles = [
        oplabsProfile
        fireflyProfile
        persoProfile
      ];
    };
  };

  nebula.userSelector = machine:
    if machine.features.work
    then cfg.users.workUser
    else cfg.users.personalUser;
}
