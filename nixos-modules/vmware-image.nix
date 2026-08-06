# VMware image generation for NixOS VMs
{
  lib,
  modulesPath,
  machine,
  ...
}:
{
  imports = lib.optionals machine.features.fusion [
    "${modulesPath}/virtualisation/vmware-image.nix"
  ];
}
