{
  config,
  lib,
  pkgs,
  ...
}:
{
  enable = true;

  aggressiveResize = true;
  baseIndex = 1;
  clock24 = true;
  escapeTime = 0;
  historyLimit = 50000;
  keyMode = "emacs";
  mouse = true;
  newSession = false;
  sensibleOnTop = true;
  shortcut = "z";
  terminal = "screen-256color";

  extraConfig = ''
    set -g renumber-windows on
    set -g set-clipboard on
    set -g pane-active-border-style 'fg=magenta,bg=default'
    set -g pane-border-style 'fg=brightblack,bg=default'

    set -g status-right-length 100
    set -g status-left-length 100
    set -g status-left ""
  '';

  plugins = with pkgs.tmuxPlugins; [
    yank
    resurrect

    # Periodic autosave only; auto-restore is deliberately off so a fresh
    # server starts with one session rather than every session that was
    # alive at the last save. `prefix + C-r` still restores on demand.
    continuum

    {
      plugin = tmux-thumbs;
      extraConfig = ''
        set -g @thumbs-osc52 1
        set -g @thumbs-unique enabled
        set -g @thumbs-reverse enabled
      '';
    }
    tmux-fzf
    fzf-tmux-url

    {
      plugin = tmux-floax;
      extraConfig = ''
        set -g @floax-width '80%'
        set -g @floax-height '80%'
        set -g @floax-border-color 'magenta'
        set -g @floax-text-color 'blue'
        set -g @floax-bind 'p'
        set -g @floax-change-path 'true'
      '';
    }
  ];

  tmuxp = {
    enable = true;

    workspaces = lib.optionalAttrs config.programs.gh.enable {
      "prs" = {
        session_name = "Pull Requests 🔄";
        start_directory = "~/";
        windows = [
          {
            window_name = "Dashboard";
            layout = "main-horizontal";
            options = {
              "main-pane-height" = "33%";
            };
            panes = [
              {
                focus = true;
                shell_command = "exec ${pkgs.prs}/bin/prs -q 'type:pr user-review-requested:@me state:open'";
              }
              {
                shell_command = "exec ${pkgs.prs}/bin/prs -q 'type:pr review-requested:@me -user-review-requested:@me state:open'";
              }
            ];
          }
        ];
      };
    };
  };
}
