{
  ...
}:
{
  config = {
    # enable everything except vscode
    catppuccin.enable = true;
    catppuccin.vscode.profiles.default.enable = false;

    catppuccin.flavor = "frappe";
    catppuccin.tmux.extraConfig = ''
      set -g @catppuccin_window_status_style "rounded"
      set -g @catppuccin_window_text " #W"
      set -g @catppuccin_window_current_text " #W"
      set -g @catppuccin_window_flags "icon"
      set -g @catppuccin_window_current_number_color "#{@thm_green}"

      set -g status-right "#{E:@catppuccin_status_session}"
    '';
  };
}
