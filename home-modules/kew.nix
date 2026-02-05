{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.kew;

  # Config directory differs by platform
  configDir = if pkgs.stdenv.isDarwin then "Library/Preferences/kew" else ".config/kew";

  # Convert bool to "0" or "1" string for kew config
  boolToStr = b: if b then "1" else "0";

  # Custom INI generator that converts bools to 0/1
  toKewINI = generators.toINI {
    mkKeyValue = generators.mkKeyValueDefault {
      mkValueString =
        v:
        if builtins.isBool v then
          boolToStr v
        else
          generators.mkValueStringDefault { } v;
    } "=";
  };

  # Generate key bindings section (has duplicate "bind" keys, can't use standard INI)
  keyBindingsText = concatMapStringsSep "\n" (
    binding:
    let
      parts = [ binding.key binding.action ] ++ optional (binding.arg != null) binding.arg;
    in
    "bind = ${concatStringsSep ", " parts}"
  ) cfg.keyBindings;

  # Main INI sections
  iniConfig = {
    miscellaneous = {
      path = cfg.musicPath;
      inherit (cfg.settings)
        allowNotifications
        hideLogo
        hideHelp
        hideSideCover
        titleDelay
        quitOnStop
        hideGlimmeringText
        replayGainCheckFirst
        saveRepeatShuffleSettings
        repeatState
        shuffleEnabled
        trackTitleAsWindowTitle
        ;
    };

    colors = {
      inherit (cfg) theme;
      inherit (cfg.settings) colorMode;
    };

    "track cover" = {
      inherit (cfg.settings) coverEnabled coverAnsi;
    };

    mouse = {
      inherit (cfg.settings) mouseEnabled;
    };

    visualizer = {
      inherit (cfg.settings)
        visualizerEnabled
        visualizerHeight
        visualizerBrailleMode
        visualizerColorType
        visualizerBarWidth
        ;
    };

    "progress bar" = {
      inherit (cfg.settings)
        progressBarElapsedEvenChar
        progressBarElapsedOddChar
        progressBarApproachingEvenChar
        progressBarApproachingOddChar
        progressBarCurrentEvenChar
        progressBarCurrentOddChar
        ;
    };
  };

  # Key binding type
  keyBindingType = types.submodule {
    options = {
      key = mkOption {
        type = types.str;
        description = "Key or key combination";
        example = "Space";
      };
      action = mkOption {
        type = types.str;
        description = "Action to perform";
        example = "playPause";
      };
      arg = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Optional argument for the action";
        example = "+5%";
      };
    };
  };

  defaultKeyBindings = [
    { key = "Space"; action = "playPause"; arg = null; }
    { key = "Shift+Tab"; action = "prevView"; arg = null; }
    { key = "Tab"; action = "nextView"; arg = null; }
    { key = "+"; action = "volUp"; arg = "+5%"; }
    { key = "="; action = "volUp"; arg = "+5%"; }
    { key = "-"; action = "volDown"; arg = "-5%"; }
    { key = "h"; action = "prevSong"; arg = null; }
    { key = "l"; action = "nextSong"; arg = null; }
    { key = "k"; action = "scrollUp"; arg = null; }
    { key = "j"; action = "scrollDown"; arg = null; }
    { key = "p"; action = "playPause"; arg = null; }
    { key = "n"; action = "toggleNotifications"; arg = null; }
    { key = "v"; action = "toggleVisualizer"; arg = null; }
    { key = "b"; action = "toggleAscii"; arg = null; }
    { key = "r"; action = "toggleRepeat"; arg = null; }
    { key = "i"; action = "cycleColorMode"; arg = null; }
    { key = "t"; action = "cycleThemes"; arg = null; }
    { key = "c"; action = "cycleVisualization"; arg = null; }
    { key = "s"; action = "shuffle"; arg = null; }
    { key = "a"; action = "seekBack"; arg = null; }
    { key = "d"; action = "seekForward"; arg = null; }
    { key = "o"; action = "sortLibrary"; arg = null; }
    { key = "m"; action = "showLyricsPage"; arg = null; }
    { key = "Shift+s"; action = "stop"; arg = null; }
    { key = "x"; action = "exportPlaylist"; arg = null; }
    { key = "."; action = "addToFavorites_playlist"; arg = null; }
    { key = "u"; action = "updateLibrary"; arg = null; }
    { key = "f"; action = "moveSongUp"; arg = null; }
    { key = "g"; action = "moveSongDown"; arg = null; }
    { key = "Enter"; action = "enqueue"; arg = null; }
    { key = "Shift+g"; action = "enqueue"; arg = null; }
    { key = "Backspace"; action = "clearPlaylist"; arg = null; }
    { key = "Alt+Enter"; action = "enqueueAndPlay"; arg = null; }
    { key = "Left"; action = "prevSong"; arg = null; }
    { key = "Right"; action = "nextSong"; arg = null; }
    { key = "Up"; action = "scrollUp"; arg = null; }
    { key = "Down"; action = "scrollDown"; arg = null; }
    { key = "F2"; action = "showPlaylist"; arg = null; }
    { key = "F3"; action = "showLibrary"; arg = null; }
    { key = "F4"; action = "showTrack"; arg = null; }
    { key = "F5"; action = "showSearch"; arg = null; }
    { key = "F6"; action = "showHelp"; arg = null; }
    { key = "PgDn"; action = "nextPage"; arg = null; }
    { key = "PgUp"; action = "prevPage"; arg = null; }
    { key = "Del"; action = "remove"; arg = null; }
    { key = "mouseMiddle"; action = "enqueueAndPlay"; arg = null; }
    { key = "mouseRight"; action = "playPause"; arg = null; }
    { key = "mouseWheelDown"; action = "scrollDown"; arg = null; }
    { key = "mouseWheelUp"; action = "scrollUp"; arg = null; }
    { key = "q"; action = "quit"; arg = null; }
    { key = "Esc"; action = "quit"; arg = null; }
    { key = "Unknown"; action = "EVENT_NONE"; arg = null; }
  ];

in
{
  options.programs.kew = {
    enable = mkEnableOption "kew music player";

    package = mkOption {
      type = types.package;
      default = pkgs.kew;
      description = "The kew package to use";
    };

    musicPath = mkOption {
      type = types.str;
      default = "~/Music";
      description = "Path to the music library";
    };

    theme = mkOption {
      type = types.str;
      default = "";
      description = "Theme name (without .theme extension). Leave empty for default.";
      example = "catpuccin";
    };

    settings = {
      # [miscellaneous]
      allowNotifications = mkOption {
        type = types.bool;
        default = true;
        description = "Allow desktop notifications";
      };

      hideLogo = mkOption {
        type = types.bool;
        default = false;
        description = "Hide the kew logo";
      };

      hideHelp = mkOption {
        type = types.bool;
        default = false;
        description = "Hide the help text";
      };

      hideSideCover = mkOption {
        type = types.bool;
        default = false;
        description = "Hide the side cover";
      };

      titleDelay = mkOption {
        type = types.int;
        default = 9;
        description = "Delay when drawing title in track view (0 for no delay)";
      };

      quitOnStop = mkOption {
        type = types.bool;
        default = false;
        description = "Exit after playing the whole playlist";
      };

      hideGlimmeringText = mkOption {
        type = types.bool;
        default = false;
        description = "Hide glimmering text on the bottom row";
      };

      replayGainCheckFirst = mkOption {
        type = types.enum [ 0 1 2 ];
        default = 0;
        description = "Replay gain: 0=track, 1=album, 2=disabled";
      };

      saveRepeatShuffleSettings = mkOption {
        type = types.bool;
        default = true;
        description = "Save repeat and shuffle settings";
      };

      repeatState = mkOption {
        type = types.int;
        default = 0;
        description = "Initial repeat state";
      };

      shuffleEnabled = mkOption {
        type = types.bool;
        default = false;
        description = "Enable shuffle by default";
      };

      trackTitleAsWindowTitle = mkOption {
        type = types.bool;
        default = true;
        description = "Set window title to current track";
      };

      # [colors]
      colorMode = mkOption {
        type = types.enum [ 0 1 2 ];
        default = 0;
        description = "Color mode: 0=16-bit palette, 1=cover-derived, 2=TrueColor theme";
      };

      # [track cover]
      coverEnabled = mkOption {
        type = types.bool;
        default = true;
        description = "Enable album cover display";
      };

      coverAnsi = mkOption {
        type = types.bool;
        default = false;
        description = "Use ANSI art for covers";
      };

      # [mouse]
      mouseEnabled = mkOption {
        type = types.bool;
        default = true;
        description = "Enable mouse support";
      };

      # [visualizer]
      visualizerEnabled = mkOption {
        type = types.bool;
        default = true;
        description = "Enable the audio visualizer";
      };

      visualizerHeight = mkOption {
        type = types.int;
        default = 6;
        description = "Height of the visualizer";
      };

      visualizerBrailleMode = mkOption {
        type = types.bool;
        default = false;
        description = "Use braille characters for visualizer";
      };

      visualizerColorType = mkOption {
        type = types.enum [ 0 1 2 3 ];
        default = 2;
        description = "Visualizer color layout: 0=lighten, 1=height-based, 2=reversed, 3=reversed darken";
      };

      visualizerBarWidth = mkOption {
        type = types.enum [ 0 1 2 ];
        default = 2;
        description = "Visualizer bar width: 0=thin, 1=double, 2=auto";
      };

      # [progress bar]
      progressBarElapsedEvenChar = mkOption {
        type = types.str;
        default = "━";
        description = "Progress bar elapsed even character";
      };

      progressBarElapsedOddChar = mkOption {
        type = types.str;
        default = "━";
        description = "Progress bar elapsed odd character";
      };

      progressBarApproachingEvenChar = mkOption {
        type = types.str;
        default = "━";
        description = "Progress bar approaching even character";
      };

      progressBarApproachingOddChar = mkOption {
        type = types.str;
        default = "━";
        description = "Progress bar approaching odd character";
      };

      progressBarCurrentEvenChar = mkOption {
        type = types.str;
        default = "━";
        description = "Progress bar current even character";
      };

      progressBarCurrentOddChar = mkOption {
        type = types.str;
        default = "━";
        description = "Progress bar current odd character";
      };
    };

    keyBindings = mkOption {
      type = types.listOf keyBindingType;
      default = defaultKeyBindings;
      description = "Key bindings configuration";
      example = literalExpression ''
        [
          { key = "Space"; action = "playPause"; }
          { key = "+"; action = "volUp"; arg = "+5%"; }
        ]
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra configuration to append to kewrc";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # Symlink themes from the package
    home.file."${configDir}/themes".source = "${cfg.package}/share/kew/themes";

    # Generate kewrc
    home.file."${configDir}/kewrc".text = ''
      ${toKewINI iniConfig}

      [key bindings]

      ${keyBindingsText}

      ${cfg.extraConfig}
    '';
  };
}
