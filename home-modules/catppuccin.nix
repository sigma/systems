_: {
  config = {
    # enable everything except vscode
    catppuccin.enable = true;
    catppuccin.vscode.profiles.default.enable = false;

    # catppuccin.gemini-cli themes home-manager's `programs.gemini-cli`, which
    # upstream renamed to `programs.antigravity-cli` — leaving the module to
    # trip the rename warning on every eval. We install Gemini CLI via Homebrew
    # (darwin-modules/apps/gemini-cli.nix) and use no home-manager module for
    # it, so there is nothing to theme here.
    catppuccin.gemini-cli.enable = false;

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
