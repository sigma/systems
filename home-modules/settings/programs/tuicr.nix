# tuicr configuration (see home-modules/tuicr.nix for the module).
#
# Installed everywhere via home.packages, so enable the config everywhere too
# (matches how hunk is wired).
_: {
  enable = true;

  settings = {
    # tuicr bundles catppuccin themes directly, so unlike herdr this needs no
    # hex overrides — pick frappe to match the rest of the config.
    theme = "catppuccin-frappe";

    # Single-character leader for panel focus / sidebar / comment shortcuts.
    leader = ",";

    # Review comment taxonomy (Conventional Comments-inspired). `definition`
    # feeds the exported legend that LLMs read; colors are ANSI names (mapped by
    # the frappe theme) except nit, which uses frappe peach. Tweak freely.
    comment_types = [
      {
        id = "issue";
        definition = "a defect or problem that should be fixed";
        color = "red";
      }
      {
        id = "suggestion";
        definition = "a specific, actionable improvement to consider";
        color = "blue";
      }
      {
        id = "question";
        definition = "ask for clarification of intent or behavior";
        color = "yellow";
      }
      {
        id = "nit";
        label = "nitpick";
        definition = "minor, non-blocking style or preference";
        color = "#ef9f76"; # frappe peach
      }
      {
        id = "praise";
        definition = "call out something done well";
        color = "green";
      }
      {
        id = "thought";
        definition = "a non-blocking idea or observation; no action required";
        color = "magenta";
      }
    ];
  };
}
