# Devbox guest configuration — virtio drivers and QEMU guest agent
#
# Both tart and kvm use QEMU/virtio under the hood.
{
  lib,
  machine,
  ...
}:
lib.mkIf machine.features.devbox {
  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_blk"
    "virtio_net"
    "virtio_scsi"
  ];

  services.qemuGuest.enable = true;
}
