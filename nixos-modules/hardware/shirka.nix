# Hardware quirks specific to shirka
{
  lib,
  machine,
  ...
}:
with lib;
mkIf (machine.alias == "shirka") {
  services.udev.extraHwdb = ''
    # Compx 2.4G wireless trackball - disable acceleration, slow speed
    evdev:input:b0003v25A7pFA61*
     LIBINPUT_ACCEL_PROFILE=flat
     LIBINPUT_ACCEL_SPEED=-1.0
  '';

  # "Audio" USB key, mounted on demand under /media/music.
  # exfat carries no ownership, so it is mapped to yann (uid 1000 / gid 100
  # "users", the dynamically allocated values on this host).
  fileSystems."/media/music" = {
    device = "/dev/disk/by-uuid/69DA-653C";
    fsType = "exfat";
    options = [
      "noauto" # not mounted at boot...
      "x-systemd.automount" # ...but on first access to /media/music
      "x-systemd.idle-timeout=5min" # unmounted again once idle
      "nofail" # never block boot when the key is absent
      "uid=1000"
      "gid=100"
      "fmask=0133"
      "dmask=0022"
    ];
  };

  # Provides `eject-music`, which unmounts and powers down the key without
  # leaving the automount trigger armed behind it.
  nebula.removableMounts.music = {
    mountPoint = "/media/music";
    uuid = "69DA-653C";
  };
}
