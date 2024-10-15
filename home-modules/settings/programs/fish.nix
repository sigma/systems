{
  pkgs,
  lib,
  config,
  ...
}: let
  normalizePlugin = plugin:
    if builtins.typeOf plugin == "string"
    then {
      name = plugin;
      inherit (pkgs.fishPlugins.${plugin}) src;
    }
    else plugin;
in {
  enable = true;

  preferAbbrs = true;

  plugins = builtins.map normalizePlugin ([
      "autopair"
      "plugin-git"
      {
        name = "fish-abbreviation-tips";
        src = pkgs.fetchFromGitHub {
          owner = "gazorby";
          repo = "fish-abbreviation-tips";
          rev = "0.7.0";
          sha256 = "sha256-F1t81VliD+v6WEWqj1c1ehFBXzqLyumx5vV46s/FZRU=";
        };
      }
    ]
    ++ lib.optionals config.programs.fzf.enable [
      "fzf-fish"
      "fifc"
    ]);

  useTide = true;

  tideOptions = [
    "--style=Rainbow"
    "--prompt_colors='True color'"
    "--show_time=No"
    "--rainbow_prompt_separators=Round"
    "--powerline_prompt_heads=Round"
    "--powerline_prompt_tails=Round"
    "--powerline_prompt_style='Two lines, character and frame'"
    "--prompt_connection=Solid"
    "--powerline_right_prompt_frame=Yes"
    "--prompt_connection_andor_frame_color=Dark"
    "--prompt_spacing=Sparse"
    "--icons='Many icons'"
    "--transient=No"
  ];

  shellAliases =
    lib.optionalAttrs config.programs.bat.enable {
      "cat" = "bat -pp";
    }
    // lib.optionalAttrs config.programs.thefuck.enable {
      "f" = "fuck";
    };

  functions = {
    "fish_greeting" = "";
    "mkcd" = {
      body = "mkdir -p $argv[1] && cd $argv[1]";
      description = "Create a directory and navigate into it";
      wraps = "mkdir";
    };
  };
}
