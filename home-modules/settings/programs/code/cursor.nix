{...}: {
  userSettings = {
    "cursor.cpp.disabledLanguages" = [
      "plaintext"
      "markdown"
      "scminput"

      # for all intents and purposes, we should treat magit editors as
      # readonly. Plus we use tab extensively in there.
      "magit"
    ];
  };
}
