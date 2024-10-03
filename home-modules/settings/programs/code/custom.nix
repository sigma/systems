{
  pkgs,
  extSet,
  ...
}: {
  userSettings = {
    "editor.cursorBlinking" = "solid";
    "editor.cursorSurroundingLines" = 5;
    "editor.fontFamily" = "Fira Code, Menlo, Monaco, 'Courier New', monospace";
    "editor.fontLigatures" = "'cv01', 'cv02', 'cv04', 'ss01', 'ss05', 'cv18', 'ss03', 'cv16', 'cv31'";
    "editor.fontSize" = 14;
    "editor.minimap.enabled" = false;
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

    "github.copilot.editor.enableAutoCompletions" = true;
    "github.copilot.enable" = {
      "*" = true;
      "plaintext" = false;
      "markdown" = false;
      "scminput" = false;
    };

    "telemetry.telemetryLevel" = "off";

    "terminal.external.osxExec" = "${pkgs.wezterm}/bin/wezterm";
    "terminal.integrated.cursorBlinking" = true;
    "terminal.integrated.fontFamily" = "Fira Code, SauceCodePro Nerd Font Mono, Menlo, Monaco, 'Courier New', 'monospace'";
    "terminal.integrated.fontSize" = 13;
    "terminal.integrated.fontWeight" = "600";
    "terminal.integrated.inheritEnv" = false;

    "workbench.activityBar.orientation" = "vertical";
    "workbench.colorTheme" = "Monokai Dimmed";
    "workbench.iconTheme" = "vscode-icons";
    "workbench.editor.enablePreviewFromQuickOpen" = false;
    "workbench.editor.enablePreview" = false;
    "workbench.editor.revealIfOpen" = true;
    "workbench.editorAssociations" = {
      "*.ipynb" = "jupyter-notebook";
    };

    "files.autoSave" = "onFocusChange";
    "diffEditor.ignoreTrimWhitespace" = false;
    "vsicons.dontShowNewVersionMessage" = true;
    "[typescript]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
    };
    "[jsonc]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
    };
    "[yaml]" = {
      "editor.defaultFormatter" = "redhat.vscode-yaml";
    };
    "[javascript]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
    };
    "redhat.telemetry.enabled" = false;
    "python.languageServer" = "Default";
    "cursor.cpp.disabledLanguages" = [
      "plaintext"
      "markdown"
      "scminput"
    ];
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
      ms-toolsai.jupyter-keymap
      ms-toolsai.jupyter-renderers
      ms-toolsai.vscode-jupyter-cell-tags
      ms-toolsai.vscode-jupyter-slideshow
      ms-toolsai.jupyter
      ms-python.debugpy
      ms-python.python
      ms-python.vscode-pylance
      ms-vscode-remote.remote-containers
      ms-vscode-remote.remote-ssh
      ms-vscode-remote.remote-ssh-edit
      ms-vscode.remote-explorer
      ms-vscode.remote-repositories
      ms-vscode.remote-server
      zhuangtongfa.material-theme
      vscode-icons-team.vscode-icons
      esbenp.prettier-vscode
      ms-vscode.vscode-speech
      tamasfe.even-better-toml
      shd101wyy.markdown-preview-enhanced
    ])
    ++ (with extSet.vscode-marketplace-release; [
      rust-lang.rust-analyzer
    ]);
}
