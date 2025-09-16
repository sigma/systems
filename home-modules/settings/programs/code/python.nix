{ extSet, ... }:
{
  userSettings = {
    "python.languageServer" = "Default";
  };

  extensions = with extSet.vscode-marketplace; [
    ms-toolsai.jupyter-keymap
    ms-toolsai.jupyter-renderers
    ms-toolsai.vscode-jupyter-cell-tags
    ms-toolsai.vscode-jupyter-slideshow
    ms-toolsai.jupyter
    ms-python.debugpy
    ms-python.python
    ms-python.vscode-pylance
  ];
}
