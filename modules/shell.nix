{inputs, ...}: {
  imports = [
    inputs.devshell.flakeModule
    inputs.pre-commit-hooks-nix.flakeModule
    inputs.treefmt-nix.flakeModule
    inputs.flake-root.flakeModule
  ];

  perSystem = {
    pkgs,
    config,
    ...
  }: let
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

    systemBootstrap = "";

    systemBuild =
      if isDarwin
      then ''
        ${pkgs.nix}/bin/nix build ".#darwinConfigurations.`hostname -s`.system"
      ''
      else ''
        ${pkgs.nix}/bin/nix run ".#home-manager" --  build --flake ".#`hostname -s`"
      '';

    systemActivate =
      if isDarwin
      then ''
        ${pkgs.nix}/bin/nix run ".#darwin-rebuild" -- switch --flake ".#`hostname -s`"
      ''
      else ''
        ${pkgs.nix}/bin/nix run ".#home-manager" --  switch --flake ".#`hostname -s`"
      '';
  in {
    pre-commit.settings.hooks = {
      markdownlint.enable = true;
      treefmt.enable = true;

      treefmt.settings.formatters = [
        pkgs.alejandra
        pkgs.mdformat
        pkgs.beautysh
      ];

      flake-lock = {
        enable = true;
        name = "Unique flake inputs";
        description = "Check that all inputs are at a single version";
        files = "^flake\\.lock$";
        entry = "${pkgs.bash}/bin/bash -c '! ${pkgs.ripgrep}/bin/rg _\\\\d flake.lock'";
        pass_filenames = false;
      };
    };

    treefmt.config = {
      inherit (config.flake-root) projectRootFile;
      package = pkgs.treefmt;
      # formatters
      programs.alejandra.enable = true;
      programs.mdformat.enable = true;
      programs.beautysh.enable = true;
    };

    devshells.default = {
      devshell = {
        name = "system-shell";
        # automatically enable pre-commit hooks in that shell
        startup.pre-commit.text = config.pre-commit.installationScript;
      };

      packages = with pkgs; [
        nix
        nil # for VSCode integration.
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
      ];
    };
  };
}
