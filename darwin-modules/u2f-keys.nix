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
      "${user.login}:WrV88BbMsJUtWG9qzj3sw9i26B8s9vxk/Sg+4vmsbJJlZV6RjsXjK8Ym0b7Jqo3aRVUxz3UM9rigDGg+RM/J+Q==,M1b0VZapkWXjMS8LEN3RaYX7XgXsvYwJ0dOuISfN4RNsBNywqypKpvRnlGC5UvmUY4CL3mPrLRFzQedr4w+xuw==,es256,+presence"
    ]
    ++ optionals (machine.name == "spectre.local") [
      # desktop titan
      "${user.login}:7fZp73vnETk6Nen9OqNu49XEnQvlpqIIYYeNJDM4p/w1DprKpyqw8kvRCalbqMNwfLaElmbhHYKN4nKvMvoTPg==,yxC16UIBA7Ajkr/2uVVGx5DUCPLJOEYXHi8bs0KrTlFSL4SH+eF9rChm6V13jcldqSfL/d66REtrbRYqg5/0xQ==,es256,+presence"
    ];
}
