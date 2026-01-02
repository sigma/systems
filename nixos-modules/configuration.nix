{
  machine,
  user,
  pkgs,
  lib,
  ...
}:
{
  # Disable documentation on fusion VMs to reduce image size
  documentation.enable = lib.mkDefault (!machine.features.fusion);
  documentation.man.enable = lib.mkDefault (!machine.features.fusion);
  documentation.doc.enable = lib.mkDefault (!machine.features.fusion);
  documentation.info.enable = lib.mkDefault (!machine.features.fusion);
  documentation.nixos.enable = lib.mkDefault (!machine.features.fusion);

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
