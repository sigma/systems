# Devbox boot configuration — ensures the installed system uses the right
# boot loader and EFI settings for virtual machines.
{
  lib,
  machine,
  ...
}:
lib.mkIf machine.features.devbox {
  # VMs use systemd-boot with EFI
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
