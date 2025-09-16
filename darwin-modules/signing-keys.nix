{
  lib,
  machine,
  user,
  ...
}:
with lib;
{
  home-manager.users.${user.login} = optionalAttrs (machine.name == "ash.local") {
    programs.jujutsu.settings.signing.key =
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBCH9S6aF3W4/pKY+s/FpZAl8zIXXxI7LHE4fVd+foYdXtQI2mhiIyBX4jtbYkhACOSha5i2TPYKpBqy3NtI/utc=";
  };
}
