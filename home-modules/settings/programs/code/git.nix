{extSet, ...}: {
  userSettings = {
    "git.autofetch" = true;
    "git.confirmSync" = false;
    "git.allowForcePush" = true;
    "git.confirmForcePush" = false;
    "git.enableSmartCommit" = true;
  };

  extensions =
    (with extSet.vscode-marketplace; [
      github.codespaces
      github.copilot
      github.remotehub
      github.vscode-github-actions
      github.vscode-pull-request-github

      vsls-contrib.gistfs
    ])
    ++ (with extSet.vscode-marketplace-release; [
      github.copilot-chat
    ]);
}
