{ lib, pkgs, machine, ... }: 
  lib.optionalAttrs (machine.isWork) {
    # those files are handled by corp and will be reverted anyway, so
    # skip the warning about them being overwritten.
    environment.etc = {
      "shells".copy = true;
      "zshrc".copy = true;
      # leave bashrc alone, I don't use bash
      "bashrc".enable = false;
    };

    environment.systemPackages = [
      pkgs.gitGoogle
    ];
  }