let
  name = "Yann Hodique";
in
{
  corpUser = {
    inherit name;
    login = "yhodique";
    email = "yhodique@google.com";
  };

  personalUser = {
    inherit name;
    login = "yann";
    email = "yann.hodique@gmail.com";
  };
}
