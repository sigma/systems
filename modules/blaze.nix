{
  config,
  lib,
  pkgs,
  ...
}: let
  platform =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "darwin"
    else "linux";
in {
  home.file.".blazerc".text = ''
    try-import %workspace%/experimental/users/yhodique/config/${platform}.blazerc
    import %workspace%/experimental/users/yhodique/config/blazerc
  '';

  home.file.".exoblazerc".text = ''
    startup --noexoblaze
  '';
}
