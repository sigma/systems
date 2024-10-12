{pkgs, ...}: {
  enable = true;
  preferAbbrs = true;
  plugins =
    builtins.map (name: {
      inherit name;
      inherit (pkgs.fishPlugins.${name}) src;
    }) [
      "autopair"
      "fzf-fish"
    ];
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
  tideRightSegments = [
    "status"
    "cmd_duration"
    "context"
    "jobs"
    "direnv"
    "newline" # move languages to the second line
    "python"
    "rustc"
    "java"
    "ruby"
    "go"
    "nix_shell"
  ];
}
