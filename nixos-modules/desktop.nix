{
  inputs,
  user,
  machine,
  pkgs,
  lib,
  ...
}:
with lib;
mkIf machine.features.interactive {
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };

  environment.systemPackages = with pkgs; [
    alacritty
    fuzzel
    noctalia-shell
    swaylock
    waybar

    # chromium doesn't seem super happy about wayland right now
    (stdenv.mkDerivation {
      pname = "chromium-gpu-fixed";
      version = chromium.version;

      buildInputs = [
        chromium
        makeWrapper
      ];

      unpackPhase = "true";
      installPhase = ''
        mkdir -p $out/bin
        makeWrapper ${chromium}/bin/chromium $out/bin/chromium --add-flags "--disable-gpu-compositing"
      '';
    })

    # sound control
    pavucontrol
  ];

  programs.niri.enable = true;
  programs.xwayland.enable = true;

  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
    };
  };

  user.programs.noctalia-shell = {
    enable = true;
  };

  # Screen locking and idle management
  user.services.swayidle = {
    enable = true;
    events = [
      { event = "before-sleep"; command = "${pkgs.swaylock}/bin/swaylock -f"; }
      { event = "lock"; command = "${pkgs.swaylock}/bin/swaylock -f"; }
    ];
    timeouts = [
      { timeout = 300; command = "${pkgs.swaylock}/bin/swaylock -f"; }
      { timeout = 600; command = "${pkgs.niri}/bin/niri msg action power-off-monitors"; }
    ];
  };

  user.home.pointerCursor = {
    enable = true;
    package = pkgs.catppuccin-cursors.frappePeach;
    name = "catppuccin-frappe-peach-cursors";
    size = 24;

    hyprcursor.enable = true;
    gtk.enable = true;
    x11.enable = true;

  };
}
