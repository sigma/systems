{
  lib,
  machine,
  ...
}:
lib.mkIf machine.features.fusion {
  # make sure we have the module for the virtual disk.
  boot.initrd.availableKernelModules = [ "nvme" ];

  virtualisation.vmware.guest = {
    enable = true;
    headless = !machine.features.interactive;
  };

  # Enable KVM for nested virtualization (requires VMware "Virtualize CPU" option)
  boot.kernelModules = [ "kvm" ];
  virtualisation.libvirtd.enable = false; # We just want KVM module, not full libvirt
}
