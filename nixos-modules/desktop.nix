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

  # Enable VA-API for hardware video decoding (used by mpv, etc.)
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      mesa.drivers
      libvdpau-va-gl
    ];
  };

  environment.systemPackages = with pkgs; [
    alacritty
    fuzzel
    noctalia-shell
    local.noctalia-ipc
    waybar
    wl-clipboard # Wayland clipboard for nvim, etc.
    playerctl # Media player control

    # Chromium with GPU compositing disabled (older AMD GPUs have issues with ANGLE on Wayland)
    # Use enhanced-h264ify extension for hardware video decode via VA-API
    (stdenv.mkDerivation {
      pname = "chromium-wrapped";
      version = chromium.version;

      buildInputs = [
        chromium
        makeWrapper
      ];

      unpackPhase = "true";
      installPhase = ''
        mkdir -p $out/bin
        makeWrapper ${chromium}/bin/chromium $out/bin/chromium \
          --add-flags "--disable-gpu-compositing"
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
  # Uses noctalia-shell's lock screen via quickshell IPC
  user.services.swayidle = {
    enable = true;
    events = [
      { event = "before-sleep"; command = "${pkgs.local.noctalia-ipc}/bin/noctalia-ipc call lockScreen lock"; }
      { event = "lock"; command = "${pkgs.local.noctalia-ipc}/bin/noctalia-ipc call lockScreen lock"; }
    ];
    timeouts = [
      { timeout = 300; command = "${pkgs.local.noctalia-ipc}/bin/noctalia-ipc call lockScreen lock"; }
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
