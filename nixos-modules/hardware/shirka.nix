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
}
