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

  userSettings = {
    "cursor.cpp.disabledLanguages" = [
      # for all intents and purposes, we should treat magit editors as
      # readonly. Plus we use tab extensively in there.
      "magit"
    ];
  };
}
