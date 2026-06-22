{
  config,
  lib,
  pkgs,
  machine,
  ...
}:
let
  hostName = machine.alias or machine.name;
in
{
  # Pin the system hostname so we don't end up named `ash4` / `ash5` when
  # the LAN's DHCP server hands back collision-avoiding names because of
  # stale lease entries. Mirrors what nixos-modules/configuration.nix does
  # for Linux hosts.
  networking.hostName = hostName;
  networking.localHostName = hostName;
  networking.computerName = hostName;

  services.ssh.enable = true;
  # zsh is enabled by default in nix-darwin
  programs.zsh.enable = lib.mkForce false;

  programs.fish.enable = true;
  programs.fish.useBabelfish = true;

  environment = with pkgs; {
    systemPackages = [
      coreutils-full
      htop
      vim
    ];

    shells = [
      # I don't normally use bash, but when I do I want it to be recent !
      bash
      fish
    ];
  };

  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
  };

  user.programs.fish.interactiveShellInit = ''
    fish_add_path ${config.homebrew.brewPrefix}
  '';

  security.pam.touchid.enable = true;
  security.pam.reattach.package = pkgs.stable.pam-reattach;

  system.stateVersion = 5;
}
