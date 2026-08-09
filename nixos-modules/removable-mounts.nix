# Eject helpers for on-demand ("x-systemd.automount") removable filesystems.
#
# Unmounting an automounted drive by hand is a three-step dance: the automount
# unit has to be disarmed first, otherwise the next process that so much as
# stats the mount point silently mounts the drive again. Each entry here gets a
# single command that performs the dance, reports what is holding the mount
# when it is busy, and cuts power to the device so it is safe to pull.
#
# The automount unit is deliberately left disarmed afterwards; a udev rule
# re-arms it when the drive is plugged back in.
{
  config,
  lib,
  pkgs,
  utils,
  ...
}:
with lib;
let
  cfg = config.nebula.removableMounts;

  mountType = types.submodule (
    { name, ... }:
    {
      options = {
        mountPoint = mkOption {
          type = types.path;
          description = ''
            Mount point of the removable filesystem. Must match a
            {option}`fileSystems` entry carrying `x-systemd.automount`.
          '';
        };

        uuid = mkOption {
          type = types.str;
          description = ''
            Filesystem UUID, as reported by `lsblk -no UUID <device>`. Used
            both to locate the device at eject time and to recognise the drive
            when it comes back.
          '';
        };

        command = mkOption {
          type = types.str;
          default = "eject-${name}";
          description = "Name of the generated eject command.";
        };
      };
    }
  );

  # systemd derives unit names from the escaped mount point: /media/music
  # yields media-music.mount and media-music.automount.
  unitOf = m: utils.escapeSystemdPath m.mountPoint;

  ejectScript =
    m:
    pkgs.writeShellApplication {
      name = m.command;
      runtimeInputs = with pkgs; [
        psmisc # fuser
        util-linux # lsblk
        config.systemd.package
      ];
      text = ''
        MOUNT_UNIT=${unitOf m}.mount
        AUTOMOUNT_UNIT=${unitOf m}.automount
        MOUNT_POINT=${m.mountPoint}
        BY_UUID=/dev/disk/by-uuid/${m.uuid}

        # fuser and the sysfs power-off both need root.
        if [ "$(id -u)" -ne 0 ]; then
          exec sudo -- "$0" "$@"
        fi

        rearm() {
          systemctl start "$AUTOMOUNT_UNIT" || true
        }

        # Anything short of a completed eject must leave the automount armed,
        # otherwise a failed run silently disables on-demand mounting.
        ejected=0
        cleanup() {
          if [ "$ejected" -eq 0 ]; then
            rearm
          fi
        }
        trap cleanup EXIT

        if [ ! -e "$BY_UUID" ]; then
          echo "$MOUNT_POINT: drive is not plugged in, nothing to eject."
          exit 0
        fi

        # Report blockers before disarming anything, so a busy mount leaves the
        # system exactly as it was found.
        if systemctl is-active --quiet "$MOUNT_UNIT" && fuser -m "$MOUNT_POINT" >/dev/null 2>&1; then
          echo "$MOUNT_POINT is busy. Still holding it:" >&2
          echo >&2
          fuser -vm "$MOUNT_POINT" >&2 || true
          echo >&2
          echo "An 'ACCESS' of 'c' means a process sits in the mount: cd out of it." >&2
          exit 1
        fi

        # Disarm first: with the trigger live, stopping the mount only invites
        # the next path access to mount it straight back.
        systemctl stop "$AUTOMOUNT_UNIT"

        if ! systemctl stop "$MOUNT_UNIT"; then
          echo "$MOUNT_POINT: could not unmount; automount left armed." >&2
          exit 1
        fi

        sync

        # Cut power so the drive is safe to pull. The kernel wants the whole
        # disk, not the partition the filesystem lives on.
        PART=$(readlink -f "$BY_UUID")
        PARENT=$(lsblk -no pkname "$PART" | tr -d ' \n')
        DISK=''${PARENT:-$(basename "$PART")}
        DELETE=/sys/block/$DISK/device/delete

        if [ -w "$DELETE" ]; then
          echo 1 >"$DELETE"
        else
          echo "note: $DELETE is unavailable, drive was unmounted but not powered down." >&2
        fi

        ejected=1
        echo "$MOUNT_POINT unmounted. Safe to remove; it remounts on demand when plugged back in."
      '';
    };

  # Re-arm on reinsertion rather than on removal: the power-off above already
  # makes the device vanish, so a removal event would fire while the drive is
  # still physically in the slot.
  rearmRule = m: ''
    ACTION=="add", SUBSYSTEM=="block", ENV{ID_FS_UUID}=="${m.uuid}", TAG+="systemd", RUN+="${config.systemd.package}/bin/systemctl --no-block start ${unitOf m}.automount"
  '';
in
{
  options.nebula.removableMounts = mkOption {
    type = types.attrsOf mountType;
    default = { };
    description = ''
      Removable filesystems that are mounted on demand, each of which gets a
      generated eject command.
    '';
    example = literalExpression ''
      {
        music = {
          mountPoint = "/media/music";
          uuid = "69DA-653C";
        };
      }
    '';
  };

  config = mkIf (cfg != { }) {
    environment.systemPackages = map ejectScript (attrValues cfg);
    services.udev.extraRules = concatMapStrings rearmRule (attrValues cfg);
  };
}
