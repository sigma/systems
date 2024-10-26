{pkgs, ...}: {
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
    set -g @catppuccin_window_left_separator ""
    set -g @catppuccin_window_right_separator " "
    set -g @catppuccin_window_middle_separator " █"

    set -g @catppuccin_window_number_position "right"
    set -g @catppuccin_window_default_fill "number"
    set -g @catppuccin_window_default_text "#W"
    set -g @catppuccin_window_current_fill "number"
    set -g @catppuccin_window_current_text "#W#{?window_zoomed_flag,(),}"

    set -g @catppuccin_status_modules_right "session"
    set -g @catppuccin_status_modules_left "null"

    set -g @catppuccin_status_left_separator  " "
    set -g @catppuccin_status_right_separator " "
    set -g @catppuccin_status_right_separator_inverse "no"
    set -g @catppuccin_status_fill "icon"
    set -g @catppuccin_status_connect_separator "no"
  '';
}
