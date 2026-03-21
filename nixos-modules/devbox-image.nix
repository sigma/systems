# Devbox image generation — produces the right disk format per hypervisor
#
# Exposes config.system.build.devboxImage as a unified build target:
#   tart  → raw EFI image (for ~/.tart/vms/<name>/disk.img)
#   kvm   → qcow2 EFI image (for libvirt/virsh)
#   vmware → vmdk via upstream vmwareImage module
{
  config,
  lib,
  machine,
  modulesPath,
  pkgs,
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
  # VMware uses its own upstream image module
  imports = lib.optionals (hypervisor == "vmware") [
    "${modulesPath}/virtualisation/vmware-image.nix"
  ];

  config = lib.mkIf isDevbox {
    # Boot loader config for make-disk-image (needs GRUB, not systemd-boot)
    boot.loader.systemd-boot.enable = lib.mkIf (hypervisor != "vmware") (lib.mkForce false);
    boot.loader.grub = lib.mkIf (hypervisor != "vmware") {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      device = "nodev";
    };

    system.build.devboxImage =
      if hypervisor == "vmware" then
        config.system.build.vmwareImage
      else
        import "${modulesPath}/../lib/make-disk-image.nix" {
          inherit lib config pkgs;
          diskSize = "auto";
          additionalSpace = "2048M";
          format = imageFormats.${hypervisor};
          partitionTableType = "efi";
          installBootLoader = true;
        };
  };
}
