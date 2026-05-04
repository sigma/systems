# Devbox installer ISO — a minimal NixOS ISO that auto-partitions and installs
# a bootstrap system with SSH access, ready for `nixos-rebuild switch`.
#
# This replaces devbox-image.nix. Instead of building the full system image
# on macOS (which hits cross-build hash mismatches), we boot this ISO inside
# the VM and let it install a minimal NixOS natively on Linux.
#
# Two impure inputs are read from the environment when present:
#   DEVBOX_SSH_KEY        — path to the new devbox user's SSH private key
#   DEVBOX_PARENT_PUBKEY  — path to the parent host's SSH public key
# When set, the installer drops the private key at /home/<user>/.ssh/id_ed25519
# and authorizes the parent's public key so `devbox-rebuild` can SSH in.
{
  config,
  lib,
  machine,
  modulesPath,
  pkgs,
  user,
  ...
}:
let
  isDevbox = machine.features.devbox;

  sshKeyPath = builtins.getEnv "DEVBOX_SSH_KEY";
  hasSshKey = sshKeyPath != "";
  sshKeyFile = if hasSshKey then pkgs.writeText "devbox-id_ed25519" (builtins.readFile sshKeyPath) else null;

  parentPubKeyPath = builtins.getEnv "DEVBOX_PARENT_PUBKEY";
  hasParentPubKey = parentPubKeyPath != "";
  parentPubKey = if hasParentPubKey then lib.removeSuffix "\n" (builtins.readFile parentPubKeyPath) else "";

  authorizedKeysAttr = lib.optionalString hasParentPubKey ''
    users.users.${user.login}.openssh.authorizedKeys.keys = [ "${parentPubKey}" ];
    users.users.root.openssh.authorizedKeys.keys = [ "${parentPubKey}" ];
  '';

  # Auto-install script that runs inside the ISO
  autoInstallScript = pkgs.writeShellScript "devbox-auto-install" ''
    set -euo pipefail

    echo "=== Devbox auto-installer ==="

    # Wait for disk to appear
    while [ ! -b /dev/vda ]; do sleep 1; done

    echo "Partitioning /dev/vda..."
    ${pkgs.parted}/bin/parted -s /dev/vda -- \
      mklabel gpt \
      mkpart ESP fat32 1MiB 512MiB \
      set 1 esp on \
      mkpart nixos ext4 512MiB 100%

    echo "Formatting..."
    ${pkgs.dosfstools}/bin/mkfs.fat -F 32 -n boot /dev/vda1
    ${pkgs.e2fsprogs}/bin/mkfs.ext4 -L nixos /dev/vda2

    echo "Mounting..."
    mount /dev/vda2 /mnt
    mkdir -p /mnt/boot
    mount /dev/vda1 /mnt/boot

    echo "Generating hardware config..."
    nixos-generate-config --root /mnt

    echo "Writing bootstrap configuration..."
    cat > /mnt/etc/nixos/configuration.nix << 'NIXCFG'
    { config, pkgs, lib, ... }:
    {
      imports = [ ./hardware-configuration.nix ];

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      networking.hostName = "${machine.hostKey}";
      networking.networkmanager.enable = true;

      # Enable SSH for remote rebuild
      services.openssh = {
        enable = true;
        settings.PermitRootLogin = "yes";
      };

      # Create user with initial password (change after first login)
      users.users.${user.login} = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        initialPassword = "devbox";
      };

      users.users.root.initialPassword = "devbox";

      ${authorizedKeysAttr}

      # Allow passwordless sudo for rebuild
      security.sudo.wheelNeedsPassword = false;

      # Enable flakes
      nix.settings.experimental-features = [ "nix-command" "flakes" ];

      # Basic packages for bootstrap
      environment.systemPackages = with pkgs; [
        git
        vim
      ];

      system.stateVersion = "25.11";
    }
    NIXCFG

    echo "Running nixos-install..."
    nixos-install --no-root-passwd

    ${lib.optionalString hasSshKey ''
      echo "Installing devbox SSH user key..."
      USER_UID=$(${pkgs.gnugrep}/bin/grep "^${user.login}:" /mnt/etc/passwd | ${pkgs.coreutils}/bin/cut -d: -f3)
      USER_GID=$(${pkgs.gnugrep}/bin/grep "^${user.login}:" /mnt/etc/passwd | ${pkgs.coreutils}/bin/cut -d: -f4)
      ${pkgs.coreutils}/bin/install -m 0700 -o "$USER_UID" -g "$USER_GID" -d /mnt/home/${user.login}/.ssh
      KEY=/mnt/home/${user.login}/.ssh/id_ed25519
      ${pkgs.coreutils}/bin/install -m 0600 -o "$USER_UID" -g "$USER_GID" \
        ${sshKeyFile} "$KEY"
      # ssh-keygen refuses to read keys with permissive perms; derive the
      # public half from the post-install copy (mode 0600), not the store path.
      ${pkgs.openssh}/bin/ssh-keygen -y -f "$KEY" > "$KEY.pub"
      ${pkgs.coreutils}/bin/chown "$USER_UID:$USER_GID" "$KEY.pub"
      ${pkgs.coreutils}/bin/chmod 0644 "$KEY.pub"
    ''}

    echo "=== Installation complete, shutting down ==="
    poweroff
  '';
in
{
  config = lib.mkIf isDevbox {
    # Expose VM creation parameters so devbox-install can query them
    system.build.devboxNested = lib.boolToString (machine.devbox.nested or false);

    # Build a custom auto-install ISO
    system.build.devboxInstaller = (import "${modulesPath}/../lib/eval-config.nix" {
      inherit (machine) system;
      modules = [
        "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
        {
          # Enable serial console so tart --serial shows output
          # Apple Virtualization.framework uses virtio console (hvc0)
          boot.kernelParams = [ "console=hvc0" "console=tty0" ];
          systemd.services."serial-getty@hvc0".enable = true;

          # Run auto-install on boot
          systemd.services.devbox-auto-install = {
            description = "Devbox auto-installer";
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            path = with pkgs; [
              util-linux   # mount, umount
              coreutils    # mkdir, cat, sleep
              nixos-install-tools  # nixos-install, nixos-generate-config
              nix          # needed by nixos-install
              systemd      # poweroff
            ];
            environment.NIX_PATH = "nixpkgs=${pkgs.path}";
            serviceConfig = {
              Type = "oneshot";
              ExecStart = autoInstallScript;
              StandardOutput = "journal+console";
              StandardError = "journal+console";
            };
          };
        }
      ];
    }).config.system.build.isoImage;
  };
}
