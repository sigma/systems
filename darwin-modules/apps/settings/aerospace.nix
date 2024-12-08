{
  config,
  lib,
  machine,
  ...
}: let
  cfg = config.programs.aerospace;
in {
  programs = {
    aerospace = {
      enable = true;
      workspaces = with cfg.monitors; [
        # Numbered workspaces are floating
        {name = "1";}
        {name = "2";}
        {name = "3";}
        {name = "4";}
        {name = "5";}
        {name = "6";}
        {name = "7";}
        {name = "8";}
        # Named workspaces are assigned to displays
        {
          name = "B";
          display = browser;
        }
        {
          name = "C";
          display = chat;
        }
        {
          name = "E";
          display = editor;
        }
        {
          name = "M";
          display = music;
        }
        {
          name = "N";
          display = notes;
        }
        {
          name = "T";
          display = terminal;
        }
      ];
      windowRules =
        [
          # Terminals
          {
            appId = "com.github.wez.wezterm";
            layout = "tiling";
            workspace = "T";
          }
          {
            appNameRegexSubstring = "wezterm-gui";
            layout = "tiling";
            workspace = "T";
          }
          {
            appId = "com.googlecode.iterm2";
            layout = "tiling";
            workspace = "T";
          }
          # Browser
          {
            appId = "com.google.Chrome";
            layout = "tiling";
            workspace = "B";
          }
          # Editors
          {
            appNameRegexSubstring = "Cursor";
            layout = "tiling";
            workspace = "E";
          }
          {
            appId = "com.microsoft.VSCode";
            layout = "tiling";
            workspace = "E";
          }
          {
            appId = "org.gnu.Emacs";
            layout = "floating";
            windowTitleRegexSubstring = "^posframe.*";
          }
          {
            appId = "org.gnu.Emacs";
            layout = "tiling";
            workspace = "E";
          }
          # Notes
          {
            appId = "notion.id";
            layout = "floating";
            windowTitleRegexSubstring = "Tab Preview";
          }
          {
            appId = "notion.id";
            layout = "tiling";
            workspace = "N";
          }
          # Chat
          {
            appNameRegexSubstring = "Slack";
            layout = "tiling";
            workspace = "C";
          }
          # Music
          {
            appId = "com.spotify.client";
            layout = "tiling";
            workspace = "M";
          }
          # Misc
          {
            appId = "com.apple.systempreferences";
            layout = "floating";
          }
        ]
        ++ lib.optionals machine.features.music [
          {
            appId = "com.native-instruments.Maschine 2";
            layout = "tiling";
            workspace = "M";
          }
          {
            appId = "com.native-instruments.Traktor";
            layout = "tiling";
            workspace = "M";
          }
        ];
    };
  };
}
