# Devbox guest configuration — hypervisor-aware guest tools and drivers
{
  lib,
  machine,
  ...
}:
let
  isDevbox = machine.features.devbox;
  hypervisor = if machine.devbox != null then machine.devbox.hypervisor else null;
  isQemu = hypervisor == "tart" || hypervisor == "kvm";
in
lib.mkIf isDevbox {
  # Kernel modules per hypervisor
  boot.initrd.availableKernelModules =
    lib.optionals isQemu [
      "virtio_pci"
      "virtio_blk"
      "virtio_net"
      "virtio_scsi"
    ]
    ++ lib.optionals (hypervisor == "vmware") [
      "nvme"
    ];

  # VMware guest tools
  virtualisation.vmware.guest = lib.mkIf (hypervisor == "vmware") {
    enable = true;
    headless = !machine.features.interactive;
  };

  # QEMU guest agent (tart and KVM both use Apple Virtualization / QEMU)
  services.qemuGuest.enable = isQemu;
}
