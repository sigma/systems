{
  lib,
  machine,
  user,
  ...
}:
with lib; {
  security.pam.u2f.enable = true;

  security.pam.u2f.authorizations =
    [
      # portable keys
    ]
    ++ optionals (machine.name == "ash.local") [
      # laptop low-profile key
      "${user.login}:mEJg6bvtXfOO8r3USlUbN6xaW87kBR7xAlVTfeFxdQSAh06vNXqOLgbjQu4XHbM1qdmEQNlfhrErxfR6Jv5M8A==,iiS2fAX/OMD79/nSPRtG/OPVn326dvU/qV2EkxAfVvasuE2I98odrFgGA3IRJyBF8ucC+sEMt/uVekIs01uqhA==,es256,+presence"
    ]
    ++ optionals (machine.name == "spectre.local") [
      # desktop titan
      "${user.login}:7fZp73vnETk6Nen9OqNu49XEnQvlpqIIYYeNJDM4p/w1DprKpyqw8kvRCalbqMNwfLaElmbhHYKN4nKvMvoTPg==,yxC16UIBA7Ajkr/2uVVGx5DUCPLJOEYXHi8bs0KrTlFSL4SH+eF9rChm6V13jcldqSfL/d66REtrbRYqg5/0xQ==,es256,+presence"
    ];
}
