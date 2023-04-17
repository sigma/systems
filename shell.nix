{pkgs}: let
  isDarwin = pkgs.stdenvNoCC.isDarwin;

  systemSetup =
    if isDarwin
    then ''
      set -e
      echo >&2 "Installing Nix-Darwin..."
      # setup /run directory for darwin system installations
      if ! test -L /run; then
        if ! grep -q '^run\b' /etc/synthetic.conf 2>/dev/null; then
          echo "setting up /etc/synthetic.conf..."
          echo -e "run\tprivate/var/run" | sudo tee -a /etc/synthetic.conf >/dev/null
          /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -B 2>/dev/null || true
          /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t 2>/dev/null || true
        fi
        if ! test -L /run; then
            echo "setting up /run..."
            sudo ln -sfn private/var/run /run
        fi
      fi
    ''
    else "";

  systemBuild =
    if isDarwin
    then ''
      ${pkgs.nixFlakes}/bin/nix build ".#darwinConfigurations.`hostname -s`.system" --experimental-features "flakes nix-command" --show-trace
    ''
    else ''
      ${pkgs.nixFlakes}/bin/nix run ".#home-manager" --experimental-features "flakes nix-command" --  build --flake ".#`hostname -s`"
    '';

  systemActivate =
    if isDarwin
    then ''
      sudo ./result/activate
    ''
    else ''
      ${pkgs.nixFlakes}/bin/nix run ".#home-manager" --experimental-features "flakes nix-command" --  switch --flake ".#`hostname -s`"
    '';
in
  pkgs.devshell.mkShell {
    packages = [pkgs.nixFlakes];

    commands = [
      {
        name = "system-install";
        category = "system";
        command = ''
          ${systemSetup}
          ${systemBuild}
          ${systemActivate}
        '';
      }
      {
        name = "system-test";
        category = "system";
        command = ''
          ${systemBuild}
        '';
      }
    ];
  }
