{ pkgs, ... }:
{
  user.programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;

    plugins = [
      pkgs.vimPlugins.nvim-treesitter.withAllGrammars
    ];

    extraLuaConfig = ''
      -- require("lazyvim_init")
    '';
  };

  user.programs.claude-code = {
    enable = true;

    agents = {

    };
  };

  user.home.packages = with pkgs; [
    # gcc
  ];
}
