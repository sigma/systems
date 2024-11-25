{
  lib,
  machine,
  ...
}:
lib.mkIf machine.features.fusion {
  # make sure we have the module for the virtual disk.
  boot.initrd.availableKernelModules = ["nvme"];

  virtualisation.vmware.guest = {
    enable = true;
    headless = !machine.features.interactive;
  };
}
