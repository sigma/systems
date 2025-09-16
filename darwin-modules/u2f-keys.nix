{
  lib,
  machine,
  user,
  ...
}:
with lib;
{
  security.pam.u2f.enable = true;

  security.pam.u2f.authorizations = [
    # portable keys
    "${user.login}:sKyQL1tKpsjH1WsM+fZXysX4Cdff/N6FjS4G3SinILb5TZOF6JrFI4hdIYzmn+2kYXJru+DMHtSj/NRYrhDldA==,kP7KSC4S4Fqgei6HBZ/BFpS/Chun+4Kn6H0fZ2OyFEvq6y9jkqz+IWTrlk3XiU4DoBcdF/uj+Muofq/DTaQCMw==,es256,+presence"
  ]
  ++ optionals (machine.name == "ash.local") [
    # home dock yubikey
    "${user.login}:QKdeeNCt3nfvAUwc2bx4A/Lamg+dtCdU5Mdsq+L+GxBkbr0eO6oWsVwE7NmzMMVhbljYDs3CDwh34zWem9pqwQ==,NYMKNF72hkXSTZCWU4sQXdy0oGbmT6B0WSuuEabso5YzRM//ZU5EEOr9TJBP64tc6mliCAIBFBdoQPi6Mcdw0g==,es256,+presence"
    # laptop low-profile key
    "${user.login}:mEJg6bvtXfOO8r3USlUbN6xaW87kBR7xAlVTfeFxdQSAh06vNXqOLgbjQu4XHbM1qdmEQNlfhrErxfR6Jv5M8A==,iiS2fAX/OMD79/nSPRtG/OPVn326dvU/qV2EkxAfVvasuE2I98odrFgGA3IRJyBF8ucC+sEMt/uVekIs01uqhA==,es256,+presence"
  ]
  ++ optionals (machine.name == "spectre.local") [
    # desktop titan
    "${user.login}:7fZp73vnETk6Nen9OqNu49XEnQvlpqIIYYeNJDM4p/w1DprKpyqw8kvRCalbqMNwfLaElmbhHYKN4nKvMvoTPg==,yxC16UIBA7Ajkr/2uVVGx5DUCPLJOEYXHi8bs0KrTlFSL4SH+eF9rChm6V13jcldqSfL/d66REtrbRYqg5/0xQ==,es256,+presence"
  ];
}
