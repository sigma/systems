{extSet, ...}: {
  extensions = with extSet.vscode-marketplace; [
    kahole.magit
    tuttieee.emacs-mcx
    usernamehw.find-jump
  ];

  keybindings = [
    {
      "key" = "alt+x g";
      "command" = "-magit.status";
    }
    {
      "key" = "alt+cmd+g";
      "command" = "magit.status";
    }
    {
      "key" = "ctrl+;";
      "command" = "findJump.activate";
    }
    {
      "key" = "ctrl+;";
      "command" = "findJump.activateWithSelection";
      "when" = "editorHasSelection";
    }
    {
      "key" = "enter";
      "command" = "-emacs-mcx.isearchExit";
    }
  ];
}
