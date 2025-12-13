# Format-on-save configuration
# Auto-format buffers on save using LSP
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.neovim-ide;
in
{
  config = mkIf cfg.enable {
    # Format on save (Lua module)
    programs.neovim-ide.luaConfigPost."50-format-on-save" = ''
      require('user.format').setup()
    '';
  };
}
