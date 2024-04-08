{inputs, ...}: {
  perSystem = {pkgs, ...}: let
    nixFlags = "--experimental-features \"flakes nix-command\"";

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

    systemBootstrap =
      if isDarwin
      then ""
      else ''
        if [ -d /google ]; then
          [ ! -e /etc/default/ciderd ] && sudo apt install ciderd
          [ ! -x /usr/bin/google-emacs ] && sudo apt install google-emacs
        fi
      '';

    systemBuild =
      if isDarwin
      then ''
        ${pkgs.nixFlakes}/bin/nix build ".#darwinConfigurations.`hostname -s`.system" ${nixFlags}
      ''
      else ''
        ${pkgs.nixFlakes}/bin/nix run ".#home-manager" ${nixFlags} --  build --flake ".#`hostname -s`"
      '';

    systemActivate =
      if isDarwin
      then ''
        sudo ./result/activate
      ''
      else ''
        ${pkgs.nixFlakes}/bin/nix run ".#home-manager" ${nixFlags} --  switch --flake ".#`hostname -s`"
      '';

    package = pkgs.stdenv.mkDerivation {
      pname = "nix-cfg-pkg";

      version = "dev";

      src = inputs.nix-filter.lib {
        root = ../.;
      };

      dontUnpack = true;

      buildPhase = ''
        ${pkgs.coreutils}/bin/true
      '';

      installPhase = ''
        mkdir -p $out/bin

        cat > $out/bin/publish <<EOF
        #!/bin/bash
        set -e

        function publish() {
          if [ -d "\$2" ]; then
            ${pkgs.rsync}/bin/rsync -av --chmod=Du=rwx,Dg=rx,Do=rx,Fu=rw,Fg=r,Fo=r -p --exclude='auth/' --delete "\$1" "\$2"
          else
            echo "\$2 does not exist"
            return 1
          fi
        }
        cd $src
        publish . /google/src/cloud/yhodique/personal/google3/experimental/users/yhodique/config/nix-systems
        EOF

        chmod a+x $out/bin/publish
      '';
    };
  in
    {
      devshells.default = {
        devshell.name = "system-shell";

        packages = [
          pkgs.nixFlakes
          pkgs.nil # for VSCode integration.
        ];

        commands = [
          {
            name = "system-bootstrap";
            category = "system";
            command = ''
              ${systemBootstrap}
            '';
          }
          {
            name = "system-install";
            category = "system";
            command = ''
              ${systemSetup}
              ${systemBootstrap}
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
        ] ++ pkgs.lib.optionals (!isDarwin) [
          {
            name = "publish";
            category = "dev";
            command = ''
              ${package}/bin/publish
            '';
          }
        ];
      };
    };
  }
