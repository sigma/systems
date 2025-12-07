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
      local lazyvim_init_path = vim.fn.expand("$HOME") .. "/.config/nvim/lazyvim_init.lua"
      if vim.fn.filereadable(lazyvim_init_path) == 1 then
        pcall(vim.cmd, 'source ' .. lazyvim_init_path)
      end
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
