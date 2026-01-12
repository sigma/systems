{
  pkgs,
  extSet,
  ...
}:
{
  userSettings = {
    "diffEditor.ignoreTrimWhitespace" = false;

    "editor.cursorBlinking" = "solid";
    "editor.cursorSurroundingLines" = 5;
    "editor.fontFamily" = "Fira Code, Menlo, Monaco, 'Courier New', monospace";
    "editor.fontLigatures" = "'cv01', 'cv02', 'cv04', 'ss01', 'ss05', 'cv18', 'ss03', 'cv16', 'cv31'";
    "editor.fontSize" = 14;
    "editor.minimap.enabled" = false;
    "editor.stickyScroll.enabled" = false;
    "editor.suggestSelection" = "first";
    "editor.tokenColorCustomizations" = {
      "textMateRules" = [
        {
          "scope" = "keyword";
          "settings" = {
            "fontStyle" = "bold";
          };
        }
        {
          "scope" = "comment";
          "settings" = {
            "fontStyle" = "italic";
          };
        }
        {
          "scope" = "constant";
          "settings" = {
            "fontStyle" = "bold";
          };
        }
      ];
    };

    "files.autoSave" = "onFocusChange";

    "rust-analyzer.cargo.targetDir" = true;

    "telemetry.telemetryLevel" = "off";

    "terminal.external.osxExec" = "${pkgs.wezterm}/bin/wezterm";
    "terminal.integrated.cursorBlinking" = true;
    "terminal.integrated.fontFamily" =
      "Fira Code, SauceCodePro Nerd Font Mono, Menlo, Monaco, 'Courier New', 'monospace'";
    "terminal.integrated.fontSize" = 13;
    "terminal.integrated.fontWeight" = "600";
    "terminal.integrated.inheritEnv" = false;

    "workbench.activityBar.orientation" = "vertical";
    "workbench.iconTheme" = "vscode-icons";
    "workbench.editor.enablePreviewFromQuickOpen" = false;
    "workbench.editor.enablePreview" = false;
    "workbench.editor.limit.enabled" = true;
    "workbench.editor.limit.perEditorGroup" = true;
    "workbench.editor.limit.value" = 10;
    "workbench.editor.limit.excludeDirty" = true;
    "workbench.editor.revealIfOpen" = true;
    "workbench.editorAssociations" = {
      "*.ipynb" = "jupyter-notebook";
    };
    "workbench.colorCustomizations" = {
      "editorLineNumber.foreground" = "#545454";
      "editorLineNumber.activeForeground" = "#ababab";
    };
    "workbench.colorTheme" = "Subliminal Next";

    "vsicons.dontShowNewVersionMessage" = true;

    "zenMode.fullScreen" = false;
    "zenMode.showTabs" = "none";
    "zenMode.hideLineNumbers" = false;

    # Remote SSH - disable dynamic forwarding to avoid conflicts with ControlMaster
    "remote.SSH.enableDynamicForwarding" = false;
  };

  keybindings = [
    {
      "key" = "ctrl+x left";
      "command" = "workbench.action.focusLeftGroup";
    }
    {
      "key" = "cmd+k cmd+left";
      "command" = "-workbench.action.focusLeftGroup";
    }
    {
      "key" = "ctrl+x ctrl+left";
      "command" = "workbench.action.moveActiveEditorGroupLeft";
    }
    {
      "key" = "cmd+k left";
      "command" = "-workbench.action.moveActiveEditorGroupLeft";
    }
    {
      "key" = "ctrl+x right";
      "command" = "workbench.action.focusRightGroup";
    }
    {
      "key" = "cmd+k cmd+right";
      "command" = "-workbench.action.focusRightGroup";
    }
    {
      "key" = "ctrl+x ctrl+right";
      "command" = "workbench.action.moveActiveEditorGroupRight";
    }
    {
      "key" = "cmd+k right";
      "command" = "-workbench.action.moveActiveEditorGroupRight";
    }

    {
      "key" = "cmd+`";
      "command" = "workbench.action.focusPanel";
    }
    {
      "key" = "cmd+`";
      "command" = "workbench.action.focusActiveEditorGroup";
      "when" = "panelFocus";
    }
  ];

  extensions =
    (with extSet.vscode-marketplace; [
      fill-labs.dependi
      dustypomerleau.rust-syntax
      ms-vscode-remote.remote-containers
      # ms-vscode-remote.remote-ssh
      ms-vscode-remote.remote-ssh-edit
      ms-vscode.remote-explorer
      ms-vscode.remote-repositories
      ms-vscode.remote-server
      konradkeska.subliminal-next
      vscode-icons-team.vscode-icons
      ms-vscode.vscode-speech
      tamasfe.even-better-toml
      shd101wyy.markdown-preview-enhanced
    ])
    ++ (with extSet.vscode-marketplace-release; [
      rust-lang.rust-analyzer
    ]);
}
