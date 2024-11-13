{
  config,
  lib,
  pkgs,
  ...
}: {
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
  shell = "${pkgs.fish}/bin/fish";
  shortcut = "z";
  terminal = "screen-256color";

  extraConfig = ''
    set -g detach-on-destroy off
    set -g renumber-windows on
    set -g set-clipboard on
    set -g pane-active-border-style 'fg=magenta,bg=default'
    set -g pane-border-style 'fg=brightblack,bg=default'

    set -g status-right-length 100
    set -g status-left-length 100
    set -g status-left ""
    set -g status-right "#{E:@catppuccin_status_session}"
  '';

  plugins = with pkgs.tmuxPlugins; [
    yank
    resurrect

    {
      plugin = continuum;
      extraConfig = ''
        set -g @continuum-restore 'on'
      '';
    }

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

  catppuccin.extraConfig = ''
    set -g @catppuccin_window_status_style "rounded"
    set -g @catppuccin_window_text " #W"
    set -g @catppuccin_window_current_text " #W"
    set -g @catppuccin_window_flags "icon"
    set -g @catppuccin_window_current_number_color "#{@thm_green}"
  '';

  tmuxp = {
    enable = true;

    workspaces = lib.optionalAttrs (config.programs.gh.enable) {
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
