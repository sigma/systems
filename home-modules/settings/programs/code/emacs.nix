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
      "key" = "ctrl+s";
      "command" = "findJump.activate";
    }
    {
      "key" = "ctrl+s";
      "command" = "findJump.activateWithSelection";
      "when" = "editorHasSelection";
    }
  ];
}
