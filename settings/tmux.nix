{
  config,
  lib,
  pkgs,
  ...
}: {
  enable = true;

  aggressiveResize = false;
  clock24 = true;

  extraConfig = ''
    set-window-option -g automatic-rename on
    set -g bell-action none

    bind i choose-window

    bind m setw monitor-activity

    bind y setw force-width 81
    bind u setw force-width 0

    bind D detach \; lock
    bind N neww \; splitw -d

    bind '~' split-window "exec htop"
    bind / command-prompt -p man: "splitw 'exec man %%'"

    # shorten command delay
    set -sg escape-time 1

    # reload ~/.tmux.conf using PREFIX r
    bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"

    # explicitly enable mouse control
    set -g mouse on

    # ----------------------
    # Status Bar
    # -----------------------
    set-option -g status on                # turn the status bar on
    #set -g status-utf8 on                  # set utf-8 for the status bar
    set -g status-interval 5               # set update frequencey (default 15 seconds)
    set -g status-justify centre           # center window list for clarity
    # set-option -g status-position top    # position the status bar at top of screen

    # visual notification of activity in other windows
    setw -g monitor-activity on
    set -g visual-activity on

    # show host name and IP address on left side of status bar
    set -g status-left-length 70
    set -g status-left "#[fg=green]: #h : #[fg=yellow]#(ifconfig en0 | grep 'inet ' | awk '{print \"en0 \" $2}') #(ifconfig en1 | grep 'inet ' | awk '{print \"en1 \" $2}') #[fg=red]#(ifconfig tun0 | grep 'inet ' | awk '{print \"vpn \" $2}') "

    # show session name, window & pane number, date and time on right side of
    # status bar
    set -g status-right-length 60
    set -g status-right "#[fg=blue]#S #I:#P #[fg=yellow]:: %d %b %Y #[fg=green]:: %l:%M %p"
  '';

  newSession = true;

  plugins = with pkgs.tmuxPlugins; [
    sessionist
    pain-control
    yank
    copycat
    resurrect
    continuum
    {
      plugin = sidebar;
      extraConfig = ''
        set -g @sidebar-tree-width '60'
        set -g @sidebar-tree-command 'tree -C'
        set -g @sidebar-key-t 'ranger,left,60,focus'
      '';
    }
    logging
    open
    fpp
    power-theme
  ];

  shortcut = "z";
  terminal = "screen-256color";
}
