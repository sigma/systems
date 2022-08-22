let
  name = "Yann Hodique";
  workEmail = "yhodique@google.com";
  primaryEmail = "yann.hodique@gmail.com";
  secondaryEmail = "yann@hodique.info";
in
{
  corpUser = {
    inherit name;
    login = "yhodique";
    email = workEmail;
    aliases = [primaryEmail secondaryEmail];
  };

  personalUser = {
    inherit name;
    login = "yann";
    email = primaryEmail;
    aliases = [secondaryEmail];
  };
}
