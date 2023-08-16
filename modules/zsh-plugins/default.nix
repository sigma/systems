{
  config,
  lib,
  machine,
  pkgs,
  ...
}: {
  home.file =
    {
      ".zsh-plugins/aliases/aliases.plugin.zsh".source = ./aliases.plugin.zsh;

      ".zsh-plugins/directory/directory.plugin.zsh".source = ./directory.plugin.zsh;

      ".zsh-plugins/iterm/iterm.plugin.zsh".source = ./iterm.plugin.zsh;

      ".zsh-plugins/utility/utility.plugin.zsh".source = ./utility.plugin.zsh;

      ".zsh-plugins/completion/completion.plugin.zsh".source = ./completion.plugin.zsh;

      ".zsh-plugins/editor/editor.plugin.zsh".source = ./editor.plugin.zsh;

      ".zsh-plugins/history/history.plugin.zsh".source = ./history.plugin.zsh;

      ".zsh-plugins/keys/keys.plugin.zsh".source = ./keys.plugin.zsh;
      ".zsh-plugins/keys/ebindkey".source = ./ebindkey;

      ".zsh-plugins/environment/environment.plugin.zsh".source = ./environment.plugin.zsh;

      ".zsh-plugins/input/input.plugin.zsh".source = ./input.plugin.zsh;

      ".zsh-plugins/less/less.plugin.zsh".source = ./less.plugin.zsh;

      ".p10k.config.zsh".source = ./p10k.config.zsh;
      ".p10k.zsh".source = ./p10k.zsh;
      ".p10k.pure.zsh".source = ./p10k.pure.zsh;

      ".p10k.generated.config.zsh".text = if machine.system == "x86_64-linux" then ''
        # location of the gcert cookie
        typeset -g POWERLEVEL9K_CERT_COOKIE_FILE="/var/run/ccache/sso-$USER/cookie"
      '' else ''
        # location of the gcert cookie
        typeset -g POWERLEVEL9K_CERT_COOKIE_FILE="$HOME/.sso/cookie"
      '';
    }
    // lib.optionalAttrs machine.isWork {
      ".zsh-plugins/google/google.plugin.zsh".source = ./google.plugin.zsh;
    };
}
