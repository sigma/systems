{
  user,
  machine,
  pkgs,
  lib,
  ...
}:
with lib;
mkIf machine.features.interactive {
  environment.pathsToLink = [ "/libexec" ];

  services.xserver = {
    enable = true;

    desktopManager = {
      xterm.enable = false;
      xfce = {
        enable = true;
        noDesktop = true;
        enableXfwm = false;
      };
    };

    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        dmenu
        i3status
        i3blocks
      ];
    };

    displayManager = {
      lightdm = {
        enable = true;
        greeters.mini = {
          enable = true;
          user = user.login;
        };
      };
    };
  };

  services.DisplayManager = {
    defaultSession = "xfce+i3";
  };

  security.pam.services = {
    i3lock-color.enable = true;
  };

  user.xsession.windowManager.i3 = {
    enable = true;
    config = {
      modifier = "Mod4";
      gaps = {
        inner = 10;
        outer = 5;
      };
    };
  };
}
