{
  lib,
  ...
}:
with lib;
{
  # temporary hack to tolerate the vivid settings until home-manager supports it
  options.programs.vivid = {
    enable = mkEnableOption "vivid";
    activeTheme = mkOption {
      type = types.str;
      default = "frappe";
      description = "The active theme to use.";
    };
  };
}
