{pkgs, ...}: let
  defaultCommand = "${pkgs.fd}/bin/fd --type f --color=always";
in {
  enable = true;

  defaultOptions = [
    "--multi"
    "--inline-info"
    "--bind='ctrl-o:execute(${pkgs.zile}/bin/zile {})+abort'"
    "--ansi"
  ];
  inherit defaultCommand;

  fileWidgetCommand = defaultCommand + " --hidden";
  fileWidgetOptions = [
    "--preview-window 'right:60%'"
    "--preview '${pkgs.bat}/bin/bat --color=always --style=header,grid --line-range :300 {}'"
  ];

  changeDirWidgetCommand = "${pkgs.fd}/bin/fd --type d --hidden --follow --exclude .git .";
  changeDirWidgetOptions = ["--preview '${pkgs.tree}/bin/tree -C {} | head -200'"];

  historyWidgetOptions = [
    "--sort"
  ];
}
