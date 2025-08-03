{
  machine,
  user,
  pkgs,
  ...
}: {
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName =
    if machine.alias != null
    then machine.alias
    else machine.name;
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Paris";
  users.users.${user.login} = {
    isNormalUser = true;
    extraGroups = ["wheel"];
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

  system.stateVersion = "25.05";
}
