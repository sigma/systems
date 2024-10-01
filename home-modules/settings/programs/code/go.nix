{...}: {
  userSettings = {
    "go.autocompleteUnimportedPackages" = true;
    "go.coverageDecorator" = {
      "type" = "gutter";
      "coveredHighlightColor" = "rgba(64,128,128,0.5)";
      "uncoveredHighlightColor" = "rgba(128,64,64,0.25)";
      "coveredGutterStyle" = "blockgreen";
      "uncoveredGutterStyle" = "blockred";
    };
    "go.coverOnSave" = true;
    "go.coverOnSingleTest" = true;
    "go.testFlags" = [
      "-short"
    ];
    "go.testOnSave" = true;
    "go.languageServerExperimentalFeatures" = {
      "diagnostics" = true;
    };
    "gopls" = {
      "usePlaceholders" = true;
    };
    "[go]" = {
      "editor.snippetSuggestions" = "none";
      "editor.formatOnSave" = true;
      "editor.codeActionsOnSave" = {
        "source.organizeImports" = "explicit";
      };
    };
    "go.toolsManagement.autoUpdate" = true;
  };
}
