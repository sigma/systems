# Devbox image generation — produces the right disk format per hypervisor
#
# Exposes config.system.build.devboxImage as a unified build target:
#   tart → raw EFI image (for ~/.tart/vms/<name>/disk.img)
#   kvm  → qcow2 EFI image (for libvirt/virsh)
{
  lib,
  machine,
  modulesPath,
  pkgs,
  config,
  ...
}:
let
  isDevbox = machine.features.devbox;
  hypervisor = if machine.devbox != null then machine.devbox.hypervisor else null;

  imageFormats = {
    tart = "raw";
    kvm = "qcow2-compressed";
  };
in
{
  config = lib.mkIf isDevbox {
    # make-disk-image needs GRUB, not systemd-boot
    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
    boot.loader.grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      device = "nodev";
    };

    system.build.devboxImage = import "${modulesPath}/../lib/make-disk-image.nix" {
      inherit lib config pkgs;
      diskSize = "auto";
      additionalSpace = "2048M";
      format = imageFormats.${hypervisor};
      partitionTableType = "efi";
      installBootLoader = true;
    };
  };
}
