# UTM/QEMU guest configuration for NixOS VMs on Apple Silicon
{
  lib,
  machine,
  pkgs,
  ...
}:
lib.mkIf machine.features.utm {
  # Virtio drivers for optimal performance
  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
    "virtio_net"
    "virtio_gpu"
  ];

  # QEMU guest agent for host-guest communication
  services.qemuGuest.enable = true;

  # SPICE agent for clipboard sharing and display scaling
  services.spice-vdagentd.enable = true;

  # KVM for nested virtualization (supported by UTM on Apple Silicon)
  boot.kernelModules = [ "kvm" ];

  # Virtio GPU for better graphics performance
  hardware.graphics.enable = true;

  # Install useful guest utilities
  environment.systemPackages = with pkgs; [
    spice-vdagent
  ];
}
