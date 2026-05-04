{
  machine,
  user,
  pkgs,
  lib,
  nixConfig,
  ...
}:
let
  # If this host is a devbox, authorize its parent's user SSH key so the
  # parent can `ssh <devbox-alias>` and `devbox-rebuild` works after the
  # tailnet alias becomes resolvable.
  parentSshKey =
    if machine.devbox != null && machine.devbox.parentHost != null then
      nixConfig.userPublicKeys.${machine.devbox.parentHost} or null
    else
      null;
in
{
  # Disable documentation on devbox VMs to reduce image size
  documentation.enable = lib.mkDefault (!machine.features.devbox);
  documentation.man.enable = lib.mkDefault (!machine.features.devbox);
  documentation.doc.enable = lib.mkDefault (!machine.features.devbox);
  documentation.info.enable = lib.mkDefault (!machine.features.devbox);
  documentation.nixos.enable = lib.mkDefault (!machine.features.devbox);

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = machine.alias or machine.name;
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Paris";
  users.users.${user.login} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = lib.optional (parentSshKey != null) parentSshKey;
  };

  programs.fish.enable = true;
  programs.fish.useBabelfish = true;

  environment = with pkgs; {
    systemPackages = [
      coreutils-full
      htop
      vim
    ];

    shells = [
      bash
      fish
    ];
  };

  services.openssh.enable = true;

  # Devboxes are throwaway and rebuilt over SSH from the parent host;
  # passwordless wheel keeps `devbox-rebuild` non-interactive.
  security.sudo.wheelNeedsPassword = lib.mkIf machine.features.devbox false;

  # Heavy substitution from cache.nixos.org during devbox-rebuild can blow
  # past the default 1024 fd limit. Bump nix-daemon and SSH login sessions
  # so manual `nixos-rebuild` and `nix build` invocations on the devbox
  # don't trip on the soft limit.
  systemd.services.nix-daemon.serviceConfig.LimitNOFILE =
    lib.mkIf machine.features.devbox 65536;
  security.pam.loginLimits = lib.mkIf machine.features.devbox [
    { domain = "*"; type = "soft"; item = "nofile"; value = "65536"; }
  ];

  # zram-backed swap soaks up RAM bursts during cargo/rust builds without
  # touching disk. Defaults to 50% of RAM.
  zramSwap.enable = lib.mkIf machine.features.devbox true;

  # Resizing the tart disk (e.g., bumping devbox.diskGB) only grows vda;
  # auto-grow the root partition + filesystem on boot to match.
  boot.growPartition = lib.mkIf machine.features.devbox true;

  system.stateVersion = "25.11";

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
      2376
    ];
  };
}
