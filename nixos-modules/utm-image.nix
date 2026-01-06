# UTM/QEMU image generation for NixOS VMs on Apple Silicon
{
  lib,
  modulesPath,
  machine,
  config,
  pkgs,
  ...
}:
{
  imports = lib.optionals machine.features.utm [
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  config = lib.mkIf machine.features.utm {
    # EFI boot for Apple Silicon (ARM64)
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Build a qcow2 image for UTM
    system.build.utmImage = import "${modulesPath}/../lib/make-disk-image.nix" {
      inherit lib config pkgs;
      format = "qcow2";
      diskSize = "auto";
      partitionTableType = "efi";
      # Use the EFI system partition
      bootSize = "512M";
      # Include the full system closure
      copyChannel = false;
    };
  };
}
