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

  system.stateVersion = "25.11";

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
      2376
    ];
  };
}
